-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Shariah Compliance Monitoring
-- ============================================================================
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.FATWA_SEARCH
  ON RULING_TEXT
  ATTRIBUTES FATWA_SOURCE, TOPIC, ISSUE_DATE, RULING_AUTHORITY
  WAREHOUSE = SHARIAH_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.FATWA_LIBRARY
);
