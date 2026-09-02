-- Generated from generator/demo_specs/aws-malaysia-islamic-finance-shariah.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-malaysia-islamic-finance-shariah
-- This is the schema that is actually deployed for MY_ISLAMIC_FINANCE_SHARIAH.

-- MY_ISLAMIC_FINANCE_SHARIAH  (Shariah Compliance Monitoring)
-- generated from generator/demo_specs/aws-malaysia-islamic-finance-shariah.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS MY_ISLAMIC_FINANCE_SHARIAH;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_SHARIAH.RAW;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_SHARIAH.CURATED;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_SHARIAH.APP;
USE DATABASE MY_ISLAMIC_FINANCE_SHARIAH;

-- 5 real regions; entity names carry their region so the two always agree
