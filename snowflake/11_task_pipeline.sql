-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Shariah Compliance Monitoring
-- ============================================================================
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_PARSE_CONTRACTS
  WAREHOUSE = SHARIAH_WH
  SCHEDULE = 'USING CRON 0 */4 * * * UTC'
  COMMENT = 'Parse new financing contracts with AI_PARSE_DOCUMENT'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_VALIDATE_COMPLIANCE
  WAREHOUSE = SHARIAH_WH
  AFTER APP.TASK_PARSE_CONTRACTS
  COMMENT = 'Validate extracted terms against BNM guidelines'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_SEARCH
  WAREHOUSE = SHARIAH_WH
  AFTER APP.TASK_VALIDATE_COMPLIANCE
  COMMENT = 'Refresh fatwa search index with new rulings'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_REFRESH_SEARCH RESUME;
ALTER TASK APP.TASK_VALIDATE_COMPLIANCE RESUME;
ALTER TASK APP.TASK_PARSE_CONTRACTS RESUME;
