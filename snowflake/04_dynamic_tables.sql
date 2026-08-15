-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Shariah Compliance Monitoring
-- ============================================================================
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
USE SCHEMA CURATED;

-- CONTRACT_COMPLIANCE_STATUS: Real-time compliance status for all financing contracts
-- Source: FINANCING_CONTRACTS, BNM_GUIDELINES, FATWA_LIBRARY
CREATE OR REPLACE DYNAMIC TABLE CURATED.CONTRACT_COMPLIANCE_STATUS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SHARIAH_WH
AS
SELECT * FROM RAW.FINANCING_CONTRACTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- FATWA_CONFLICT_MATRIX: Cross-reference matrix identifying conflicting rulings
-- Source: FATWA_LIBRARY
CREATE OR REPLACE DYNAMIC TABLE CURATED.FATWA_CONFLICT_MATRIX
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SHARIAH_WH
AS
SELECT * FROM RAW.FATWA_LIBRARY;
-- TODO: Replace with actual join/aggregation logic per demo

-- COMPLIANCE_DASHBOARD: Aggregated compliance metrics by product type and institution
-- Source: COMPLIANCE_EVENTS, FINANCING_CONTRACTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.COMPLIANCE_DASHBOARD
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SHARIAH_WH
AS
SELECT * FROM RAW.COMPLIANCE_EVENTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- AUDIT_TIMELINE: Chronological audit trail with resolution tracking
-- Source: AUDIT_RECORDS, COMPLIANCE_EVENTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.AUDIT_TIMELINE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SHARIAH_WH
AS
SELECT * FROM RAW.AUDIT_RECORDS;
-- TODO: Replace with actual join/aggregation logic per demo

