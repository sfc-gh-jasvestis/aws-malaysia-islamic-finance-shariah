-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Shariah Compliance Monitoring
-- ============================================================================
USE DATABASE ISLAMIC_SHARIAH_COMPLIANCE;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.SHARIAH_COMPLIANCE_AGENT
  COMMENT = 'Shariah Compliance Monitoring AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'ISLAMIC_SHARIAH_COMPLIANCE.APP.SHARIAH_COMPLIANCE_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'ISLAMIC_SHARIAH_COMPLIANCE.SEARCH.FATWA_SEARCH', TOOL_DESCRIPTION => 'Search documents for Islamic Finance information')
  )
  SYSTEM_PROMPT = 'You are the Shariah Compliance Intelligence Agent for Malaysia''s Islamic finance sector. You help validate contracts against BNM guidelines and fatwa rulings.';
