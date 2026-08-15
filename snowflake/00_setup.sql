-- ============================================================================
-- Shariah Compliance Monitoring
-- Automated Shariah compliance validation for Malaysia's RM 2.3T Islamic finance sector — AI_PARSE_DOCUMENT extracts contract terms, Cortex Search indexes fatwas, and Cortex Complete validates against BNM guidelines.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS ISLAMIC_SHARIAH_COMPLIANCE;
CREATE WAREHOUSE IF NOT EXISTS SHARIAH_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE SHARIAH_WH;
