-- ============================================================================
-- 08_native_reviews.sql - Snowflake-only build: live review feed without AWS.
-- Creates RAW.LIVE_REVIEWS (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_REVIEWS(N), which inserts synthetic
-- review events with the same value ranges and ~10% EXCEPTION rate as
-- aws/publish_reviews.py. Rows are inserted directly; this simulates a
-- review results feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_REVIEWS).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_REVIEWS (
  PORTFOLIO_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, AMOUNT_MYR FLOAT, REVIEW_HOURS FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_REVIEWS(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_REVIEWS (PORTFOLIO_ID, EVENT_TS, AMOUNT_MYR, REVIEW_HOURS, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'PRT-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS PORTFOLIO_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_EXCEPTION,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs constant arguments, so the exception offset is applied outside it.
    SELECT PORTFOLIO_ID, TS,
           ROUND(IFF(IS_EXCEPTION, 85000, 45000) * EXP(NORMAL(0, 0.5, RANDOM())), 0),
           ROUND(IFF(IS_EXCEPTION, 30, 6) * EXP(NORMAL(0, 0.4, RANDOM())), 0),
           IFF(IS_EXCEPTION, 'EXCEPTION', 'CLEAN'), TS, 'APP.SIMULATE_REVIEWS'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_REVIEWS
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_REVIEWS(5);
