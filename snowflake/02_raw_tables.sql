-- Synthetic portfolio-day Shariah review observations for a fictional Malaysian Islamic bank.
-- A portfolio is one financing product booked in one city branch network; the
-- bank's Shariah review team checks executed contracts for documentation
-- exceptions. The demo models review operations only and makes no Shariah rulings.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-portfolio exception propensity, drift between branch
-- process reviews, missed reviews, product-weighted exception reasons, exceptions
-- rectified without escalation, and two city-wide document system outages.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.PORTFOLIOS AS
WITH portfolios AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS PORTFOLIO_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT PORTFOLIO_INDEX,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-shariah-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-shariah-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-shariah-review')), 1000000) / 1e6 AS U_REVIEW,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-shariah-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-shariah-tier')), 1000000) / 1e6 AS U_TIER
  FROM portfolios
)
SELECT 'PRT-' || LPAD(PORTFOLIO_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic portfolio ' || LPAD(PORTFOLIO_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and product
       -- is present. All portfolios are booked in Malaysia (MYR).
       CASE MOD(PORTFOLIO_INDEX, 5) WHEN 0 THEN 'Kuala Lumpur' WHEN 1 THEN 'George Town'
            WHEN 2 THEN 'Johor Bahru' WHEN 3 THEN 'Kota Kinabalu' ELSE 'Kuching' END AS REGION,
       CASE MOD(PORTFOLIO_INDEX, 8) WHEN 0 THEN 'Personal financing-i tawarruq' WHEN 1 THEN 'Personal financing-i tawarruq'
            WHEN 2 THEN 'Personal financing-i tawarruq' WHEN 3 THEN 'SME financing-i murabahah' WHEN 4 THEN 'SME financing-i murabahah'
            WHEN 5 THEN 'Home financing-i musharakah mutanaqisah' WHEN 6 THEN 'Vehicle financing-i ijarah'
            ELSE 'Trade financing-i wakalah' END AS CATEGORY,
       PORTFOLIO_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.2 + U_AGE * 5.8, 1) AS PORTFOLIO_AGE_YEARS,
       -- Base daily probability of an escalated documentation exception 0.4%-3%; ~15% of
       -- portfolios are chronically weak (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_ESCALATION_RATE,
       7 * (1 + FLOOR(U_REVIEW * 3)) AS REVIEW_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS REVIEW_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.PORTFOLIO_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide document system outages; every portfolio in the city
  -- raises an exception that is rectified once the system recovers.
  SELECT * FROM VALUES (27, 'Kuala Lumpur'), (64, 'Kota Kinabalu') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT r.ID AS ENTITY_ID, r.PORTFOLIO_INDEX, r.CATEGORY, r.REGION, r.PORTFOLIO_AGE_YEARS,
         r.BASE_ESCALATION_RATE, r.REVIEW_INTERVAL_DAYS, r.REVIEW_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + r.PORTFOLIO_INDEX * 5, r.REVIEW_INTERVAL_DAYS) AS DAYS_SINCE_REVIEW,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-fail')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-clear')), 1000000) / 1e6 AS U_CLEAR,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-shariah-sla')), 1000000) / 1e6 AS U_SLA,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.PORTFOLIOS r CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = r.REGION
), review AS (
  SELECT *,
         IFF(DAYS_SINCE_REVIEW = 0, 1, 0) AS REVIEW_DUE,
         IFF(DAYS_SINCE_REVIEW = 0 AND U_DONE < REVIEW_COMPLETION_PROB, 1, 0) AS REVIEW_COMPLETED,
         -- Documentation drift rises between branch account reviews; weak
         -- review discipline carries it over.
         DAYS_SINCE_REVIEW / REVIEW_INTERVAL_DAYS + (1 - REVIEW_COMPLETION_PROB) AS DRIFT
  FROM base
), stress AS (
  SELECT *,
         CASE WHEN U_FAIL < LEAST(0.5, BASE_ESCALATION_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PORTFOLIO_AGE_YEARS))) / 4 THEN 2
              WHEN U_FAIL < LEAST(0.5, BASE_ESCALATION_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PORTFOLIO_AGE_YEARS))) THEN 1
              ELSE 0 END AS STRESS_COUNT
  FROM review
), cases AS (
  SELECT *,
         -- About 85% of exception-prone days produce exceptions that are
         -- escalated to the Shariah committee secretariat; the rest pass review.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.85, STRESS_COUNT, 0)) AS ESCALATED_COUNT,
         -- Exceptions rectified by operations without escalation.
         IFF(CITY_EVENT, 1, IFF(U_CLEAR < CASE CATEGORY WHEN 'Home financing-i musharakah mutanaqisah' THEN 0.20
                                                      WHEN 'Vehicle financing-i ijarah' THEN 0.12
                                                      WHEN 'Trade financing-i wakalah' THEN 0.14 ELSE 0.08 END, 1, 0)) AS RESOLVED_COUNT
  FROM stress
), measured AS (
  SELECT *,
         ESCALATED_COUNT + RESOLVED_COUNT AS EXCEPTION_COUNT,
         ROUND(CASE CATEGORY WHEN 'Personal financing-i tawarruq' THEN 420 WHEN 'SME financing-i murabahah' THEN 60
                             WHEN 'Home financing-i musharakah mutanaqisah' THEN 150 WHEN 'Vehicle financing-i ijarah' THEN 45 ELSE 12 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.8 * STRESS_COUNT)) AS CONTRACT_COUNT,
         CASE CATEGORY WHEN 'Personal financing-i tawarruq' THEN 45000 WHEN 'SME financing-i murabahah' THEN 350000
                       WHEN 'Home financing-i musharakah mutanaqisah' THEN 420000 WHEN 'Vehicle financing-i ijarah' THEN 85000
                       ELSE 600000 END
           * (0.8 + 0.4 * U_NOISE) AS AVG_CONTRACT_MYR
  FROM cases
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       CONTRACT_COUNT,
       ROUND(CONTRACT_COUNT * AVG_CONTRACT_MYR, 0) AS VALUE_MYR,
       EXCEPTION_COUNT, ESCALATED_COUNT,
       IFF(ESCALATED_COUNT > 0 AND U_SLA < 0.6, 1, 0) AS SLA_BREACHED,
       CASE WHEN EXCEPTION_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Document system outage'
            WHEN CATEGORY = 'Personal financing-i tawarruq' THEN IFF(U_TYPE < 0.5, 'Commodity trade confirmation missing', IFF(U_TYPE < 0.8, 'Execution sequence not evidenced', 'Customer acknowledgement missing'))
            WHEN CATEGORY = 'SME financing-i murabahah' THEN IFF(U_TYPE < 0.45, 'Asset purchase document missing', IFF(U_TYPE < 0.8, 'Execution sequence not evidenced', 'Customer acknowledgement missing'))
            WHEN CATEGORY = 'Home financing-i musharakah mutanaqisah' THEN IFF(U_TYPE < 0.55, 'Partnership share schedule mismatch', 'Customer acknowledgement missing')
            WHEN CATEGORY = 'Vehicle financing-i ijarah' THEN IFF(U_TYPE < 0.45, 'Rental schedule mismatch', IFF(U_TYPE < 0.8, 'Asset ownership record missing', 'Customer acknowledgement missing'))
            ELSE IFF(U_TYPE < 0.5, 'Agency appointment document missing', IFF(U_TYPE < 0.75, 'Late payment charge treatment mismatch', 'Customer acknowledgement missing')) END AS EXCEPTION_REASON,
       REVIEW_DUE, REVIEW_COMPLETED,
       ROUND(0.5 + 2.0 * DRIFT + 3.0 * STRESS_COUNT + U_NOISE * 0.8, 2) AS DOC_REJECT_PCT,
       ROUND(18 + 12 * DRIFT + 14 * STRESS_COUNT + U_NOISE * 6, 1) AS AVG_REVIEW_HOURS,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Contract file document coverage per portfolio (snapshot).
CREATE TABLE RAW.CONTRACT_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Personal financing-i tawarruq' THEN 'Commodity trade certificate'
                     WHEN 'SME financing-i murabahah' THEN 'Asset purchase invoice'
                     WHEN 'Home financing-i musharakah mutanaqisah' THEN 'Property valuation report'
                     WHEN 'Vehicle financing-i ijarah' THEN 'Vehicle ownership record'
                     ELSE 'Agency appointment letter' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'my-shariah-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'my-shariah-file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'my-shariah-file')), 5) < 1 + MOD(ABS(HASH(ID, 'my-shariah-req')), 4),
           MOD(ABS(HASH(ID, 'my-shariah-pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.PORTFOLIOS;
