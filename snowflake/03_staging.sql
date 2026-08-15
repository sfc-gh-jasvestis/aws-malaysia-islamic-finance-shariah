-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Shariah Compliance Monitoring
-- Country: MALAYSIA | Currency: MYR
-- ============================================================================
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- FATWA_LIBRARY: 200 rows — Indexed fatwa rulings from Shariah Advisory Council and DSN
-- FINANCING_CONTRACTS: 5,000 rows — Islamic financing contracts (murabahah, ijarah, musharakah, etc.)
-- AUDIT_RECORDS: 1,000 rows — Shariah audit trail and review records
-- BNM_GUIDELINES: 50 rows — Bank Negara Malaysia Shariah governance guidelines
-- COMPLIANCE_EVENTS: 8,000 rows — Compliance validation events and outcomes
