-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Shariah Compliance Monitoring
-- ============================================================================
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_malaysia_islamic_finance_shariah_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: NON_COMPLIANT_CONTRACT_ALERT
CREATE OR REPLACE ALERT APP.NON_COMPLIANT_CONTRACT_ALERT
  WAREHOUSE = SHARIAH_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Contract flagged non-compliant with Shariah principles'
IF (EXISTS (
  SELECT 1 FROM CURATED.CONTRACT_COMPLIANCE_STATUS
  WHERE 1=1 -- Condition: New contracts flagged as non-compliant
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_islamic_finance_shariah_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Shariah Compliance Monitoring: Contract flagged non-compliant with Shariah principles',
    'Contract flagged non-compliant with Shariah principles'
  );

ALTER ALERT APP.NON_COMPLIANT_CONTRACT_ALERT RESUME;

-- Alert: FATWA_CONFLICT_ALERT
CREATE OR REPLACE ALERT APP.FATWA_CONFLICT_ALERT
  WAREHOUSE = SHARIAH_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Conflicting fatwa rulings require Shariah Committee review'
IF (EXISTS (
  SELECT 1 FROM CURATED.CONTRACT_COMPLIANCE_STATUS
  WHERE 1=1 -- Condition: Conflicting DSN rulings detected on active product structures
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_islamic_finance_shariah_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Shariah Compliance Monitoring: Conflicting fatwa rulings require Shariah Committee review',
    'Conflicting fatwa rulings require Shariah Committee review'
  );

ALTER ALERT APP.FATWA_CONFLICT_ALERT RESUME;

