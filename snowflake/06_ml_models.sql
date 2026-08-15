-- ============================================================================
-- 06_ML_MODELS.SQL — ML Functions for Shariah Compliance Monitoring
-- ============================================================================
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
USE SCHEMA ML;

-- ML.CLASSIFICATION: COMPLIANCE_RISK_MODEL
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION ML.COMPLIANCE_RISK_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('TABLE', 'CURATED.CONTRACT_COMPLIANCE_STATUS'),
  TARGET_COLNAME => 'RISK_SCORE'
);

