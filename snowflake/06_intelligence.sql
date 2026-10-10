-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-exception alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_REVIEWS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic Shariah review knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.REVIEW_DOCS AS
WITH types AS (
  SELECT DISTINCT r.EXCEPTION_REASON, a.CATEGORY
  FROM RAW.PORTFOLIO_DAILY r JOIN RAW.PORTFOLIOS a ON a.ID = r.ENTITY_ID
  WHERE r.ESCALATED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, EXCEPTION_REASON)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  EXCEPTION_REASON,
  CATEGORY || ' - ' || EXCEPTION_REASON || ' exception handling' AS TITLE,
  'Synthetic demo SOP for a fictional bank. It does not state any Shariah ruling or regulatory requirement. Financing product: ' || CATEGORY
  || '. Exception reason: ' || EXCEPTION_REASON || '. '
  || 'Step 1: log the exception, link the contract reference and assign a Shariah review officer within one working day. '
  || 'Step 2: ' || CASE
       WHEN EXCEPTION_REASON = 'Commodity trade confirmation missing' THEN 'request the commodity trade confirmation from the trade operations desk, check that its timestamps match the contract file, and hold the file until it is received.'
       WHEN EXCEPTION_REASON = 'Execution sequence not evidenced' THEN 'compare the timestamps of each signed document with the documented process steps for the product, record any gap, and refer the file to the Shariah committee secretariat for its deliberation.'
       WHEN EXCEPTION_REASON = 'Customer acknowledgement missing' THEN 'ask the branch to obtain the signed customer acknowledgement within three working days and log each follow-up.'
       WHEN EXCEPTION_REASON = 'Asset purchase document missing' THEN 'request the asset purchase invoice from the branch and confirm the asset details against the financing offer letter.'
       WHEN EXCEPTION_REASON = 'Partnership share schedule mismatch' THEN 'reconcile the partnership share schedule with the core banking schedule and ask product operations to correct the system record.'
       WHEN EXCEPTION_REASON = 'Rental schedule mismatch' THEN 'reconcile the rental schedule in the contract with the core banking schedule and correct the system record.'
       WHEN EXCEPTION_REASON = 'Asset ownership record missing' THEN 'request the vehicle ownership record and attach it to the contract file before closing the review.'
       WHEN EXCEPTION_REASON = 'Agency appointment document missing' THEN 'request the signed agency appointment letter from trade operations and attach it to the contract file.'
       WHEN EXCEPTION_REASON = 'Late payment charge treatment mismatch' THEN 'compare the late payment charge entries with the bank''s approved product terms and refer the file to finance operations and the Shariah committee secretariat.'
       ELSE 'review the exception against the portfolio profile and escalate if unexplained.'
     END
  || ' Step 3: if the document rejection rate on the portfolio exceeds 5% or the average review turnaround exceeds 40 hours after triage, keep the exception open and request a branch process review. '
  || 'Step 4: record the rectification; if the exception was escalated or missed its rectification SLA, log it for the Shariah review report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.REVIEW_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, EXCEPTION_REASON
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, EXCEPTION_REASON, CONTENT FROM SEARCH.REVIEW_DOCS);

-- ---------- Document rejection rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.DOC_REJECT_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, DOC_REJECT_PCT::FLOAT AS DOC_REJECT
FROM RAW.PORTFOLIO_DAILY;
CREATE OR REPLACE VIEW ML.DOC_REJECT_TRAIN AS
SELECT * FROM ML.DOC_REJECT_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DOC_REJECT_SERIES);
CREATE OR REPLACE VIEW ML.DOC_REJECT_DETECT AS
SELECT * FROM ML.DOC_REJECT_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DOC_REJECT_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.DOC_REJECT_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DOC_REJECT_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DOC_REJECT',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.DOC_REJECT_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS DOC_REJECT, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.DOC_REJECT_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DOC_REJECT_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DOC_REJECT'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.SHARIAH_REVIEW_ANALYTICS
  TABLES (
    portfolios AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per financing portfolio (one product in one city), 90-day totals',
    risk AS ML.ESCALATION_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day exception escalation probability per portfolio',
    exceptions AS CURATED.EXCEPTION_SUMMARY PRIMARY KEY (EXCEPTION_REASON)
      COMMENT = 'Documentation exceptions, escalations and rectification SLA breaches by exception reason, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Bank-wide totals per day'
  )
  RELATIONSHIPS (risk_portfolio AS risk (ENTITY_ID) REFERENCES portfolios)
  FACTS (
    portfolios.exceptions_f AS EXCEPTION_COUNT,
    portfolios.escalated_f AS ESCALATED_COUNT,
    portfolios.breaches_f AS SLA_BREACH_COUNT,
    portfolios.contracts_f AS CONTRACT_COUNT,
    portfolios.value_f AS VALUE_MYR,
    portfolios.review_due_f AS REVIEW_DUE,
    portfolios.review_done_f AS REVIEW_COMPLETED,
    risk.escalation_prob_f AS ESCALATION_PROB_7D,
    exceptions.reason_exceptions_f AS EXCEPTION_COUNT,
    exceptions.reason_escalated_f AS ESCALATED_COUNT,
    exceptions.reason_breaches_f AS SLA_BREACH_COUNT,
    exceptions.reason_value_f AS EXPOSED_VALUE_MYR,
    daily.day_exceptions_f AS EXCEPTION_COUNT,
    daily.day_escalated_f AS ESCALATED_COUNT,
    daily.day_value_f AS VALUE_MYR
  )
  DIMENSIONS (
    portfolios.portfolio_id AS ENTITY_ID WITH SYNONYMS = ('portfolio', 'financing portfolio', 'entity'),
    portfolios.portfolio_name AS ENTITY_NAME,
    portfolios.city AS REGION WITH SYNONYMS = ('city', 'region', 'branch network')
      COMMENT = 'Malaysian city where the portfolio is booked',
    portfolios.product AS CATEGORY WITH SYNONYMS = ('product', 'financing product', 'contract type')
      COMMENT = 'Personal financing-i tawarruq, SME financing-i murabahah, Home financing-i musharakah mutanaqisah, Vehicle financing-i ijarah or Trade financing-i wakalah',
    portfolios.risk_tier AS RISK_TIER COMMENT = 'Process complexity grade 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    exceptions.exception_reason AS EXCEPTION_REASON WITH SYNONYMS = ('exception reason', 'reason', 'cause', 'finding'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    portfolios.portfolio_count AS COUNT(portfolios.portfolio_id)
      WITH SYNONYMS = ('number of portfolios', 'entities', 'number of entities'),
    portfolios.clean_review_pct AS 100 * (SUM(portfolios.contracts_f) - SUM(portfolios.exceptions_f)) / NULLIF(SUM(portfolios.contracts_f), 0)
      WITH SYNONYMS = ('clean review rate', 'first-pass clean rate')
      COMMENT = 'Contracts reviewed without an exception / contracts reviewed',
    portfolios.escalation_rate_pct AS 100 * SUM(portfolios.escalated_f) / NULLIF(SUM(portfolios.exceptions_f), 0)
      COMMENT = 'Exceptions escalated to the Shariah committee / exceptions',
    portfolios.exception_cases AS SUM(portfolios.exceptions_f) WITH SYNONYMS = ('exceptions', 'documentation exceptions', 'findings'),
    portfolios.escalated_cases AS SUM(portfolios.escalated_f) WITH SYNONYMS = ('escalations', 'committee referrals'),
    portfolios.sla_breaches AS SUM(portfolios.breaches_f) WITH SYNONYMS = ('rectification SLA misses'),
    portfolios.contracts_reviewed AS SUM(portfolios.contracts_f),
    portfolios.total_value_myr AS SUM(portfolios.value_f) WITH SYNONYMS = ('reviewed value', 'value in MYR'),
    portfolios.review_compliance_pct AS 100 * SUM(portfolios.review_done_f) / NULLIF(SUM(portfolios.review_due_f), 0)
      COMMENT = 'Branch process reviews completed / reviews due',
    risk.avg_escalation_prob AS AVG(risk.escalation_prob_f),
    exceptions.reason_exceptions AS SUM(exceptions.reason_exceptions_f),
    exceptions.reason_escalated AS SUM(exceptions.reason_escalated_f),
    exceptions.reason_breaches AS SUM(exceptions.reason_breaches_f),
    exceptions.reason_escalation_rate_pct AS 100 * SUM(exceptions.reason_escalated_f) / NULLIF(SUM(exceptions.reason_exceptions_f), 0),
    daily.daily_exceptions AS SUM(daily.day_exceptions_f),
    daily.daily_escalated AS SUM(daily.day_escalated_f),
    daily.daily_value_myr AS SUM(daily.day_value_f)
  )
  COMMENT = 'Synthetic Malaysia Islamic bank Shariah review analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.SHARIAH_REVIEW_AGENT
  COMMENT = 'Shariah review operations assistant over a synthetic Malaysian Islamic bank financing book'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give portfolio IDs and numbers with units (MYR, %). Do not give Shariah, religious or regulatory rulings; describe review operations only."
  orchestration: "Use review_analyst for contracts reviewed, documentation exceptions, escalations, rectification SLA breaches, clean review rate, process review compliance, portfolios, cities, financing products, exception reasons and escalation risk. Use sop_search for exception-handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: review_analyst
      description: "Contracts reviewed, reviewed value in MYR, documentation exceptions, escalations to the Shariah committee, rectification SLA breaches, clean review rate, process review compliance, exception reasons and escalation risk scores by portfolio, city and financing product"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic exception-handling SOPs by financing product and exception reason"
tool_resources:
  review_analyst:
    semantic_view: __DEMO_DB__.APP.SHARIAH_REVIEW_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.REVIEW_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-exception alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), PORTFOLIO_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_MYR FLOAT, REVIEW_HOURS FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION MY_ISLAMIC_FINANCE_SHARIAH_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (PORTFOLIO_ID, EVENT_TS, AMOUNT_MYR, REVIEW_HOURS, SOP_HINT)
    SELECT p.PORTFOLIO_ID, p.EVENT_TS, p.AMOUNT_MYR, p.REVIEW_HOURS,
           'Check ' || r.CATEGORY || ' exception SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_REVIEWS p
    JOIN RAW.PORTFOLIOS r ON r.ID = p.PORTFOLIO_ID
    LEFT JOIN ML.ESCALATION_RISK_SCORES s ON s.ENTITY_ID = p.PORTFOLIO_ID
    WHERE p.STATUS = 'EXCEPTION'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.PORTFOLIO_ID = p.PORTFOLIO_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('MY_ISLAMIC_FINANCE_SHARIAH_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Shariah review exception alert',
      'New review exceptions logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_EXCEPTION_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_REVIEWS p
    WHERE p.STATUS = 'EXCEPTION'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.PORTFOLIO_ID = p.PORTFOLIO_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();
-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.EXCEPTION_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.ESCALATION_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.ESCALATION_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.ESCALATION_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'PORTFOLIO_AGE_YEARS', PORTFOLIO_AGE_YEARS,
             'DOC_REJECT_PCT', DOC_REJECT_PCT, 'AVG_REVIEW_HOURS', AVG_REVIEW_HOURS,
             'DOC_REJECT_7D', DOC_REJECT_7D, 'ESCALATED_30D', ESCALATED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:ESCALATED::FLOAT, 4) AS ESCALATION_PROB_7D,
         CASE WHEN PRED:probability:ESCALATED::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:ESCALATED::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
