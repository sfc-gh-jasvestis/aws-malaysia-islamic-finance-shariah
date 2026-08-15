# Demo Script: Shariah Compliance Monitoring
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake automates Shariah compliance monitoring — AI parses contracts, indexes 200 fatwas, validates against BNM guidelines, and alerts compliance officers to non-conformance in real time"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Ustaz Dr. Mohd Nazri** | Shariah Committee Chairman | React App (SPCS) | Shariah non-compliance risk, fatwa consistency, BNM regulatory alignment, contract term validity |
| **Nurul Aisyah binti Kamal** | Compliance Officer | Amazon QuickSight | Audit trail completeness, BNM guideline changes, contract review backlog, compliance event resolution |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 5 tables | FATWA_LIBRARY (200), FINANCING_CONTRACTS (5000), AUDIT_RECORDS (1000), BNM_GUIDELINES (50), COMPLIANCE_EVENTS (8000) |
| **CURATED** | 4 Dynamic Tables | CONTRACT_COMPLIANCE_STATUS, FATWA_CONFLICT_MATRIX, COMPLIANCE_DASHBOARD, AUDIT_TIMELINE |
| **ML** | ML.CLASSIFICATION | Forecasting + anomaly detection |
| **AI** | AI_PARSE_DOCUMENT, AI_EXTRACT, COMPLETE | Classification + extraction |
| **Search** | Cortex Search | 200 documents indexed |
| **Agent** | SHARIAH_COMPLIANCE_AGENT | Semantic View + Search tools |


---

## The Story

Malaysia leads the global Islamic finance market with RM 2.3 trillion in assets governed by Shariah principles. Bank Negara Malaysia requires continuous compliance monitoring, but manual contract review creates weeks of backlog. When BNM updates guidelines, 5,000 active contracts must be re-validated — a process that currently takes the compliance team 6 weeks. Meanwhile, 6 conflicting DSN rulings on commodity murabahah remain unresolved, creating legal uncertainty.

---

## Script

### [0:00–0:45] COMPLIANCE OVERVIEW

**Show**: Compliance Overview tab

> "Malaysia's Islamic finance sector manages RM 2.3 trillion in assets under Shariah governance."

**Action**: Point at RM 2.3T total assets KPI

### [0:45–1:30] CONTRACT VALIDATION

**Show**: Contract Validation tab

> "AI_PARSE_DOCUMENT extracts 47 key terms from each financing agreement automatically."

**Action**: Show parsed contract terms side-by-side with BNM guidelines

### [1:30–2:15] FATWA INTELLIGENCE

**Show**: Fatwa Intelligence tab

> "Two hundred fatwas indexed and searchable via Cortex Search."

**Action**: Demo Cortex Search with fatwa query

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Ustaz Dr. Mohd Nazri asks: 'Which contracts violate the latest BNM guidelines on murabahah?'"

**Action**: Type compliance question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, five AWS services working together."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **AI_PARSE_DOCUMENT on Islamic financing contracts** — Only demo extracting Shariah-specific terms (murabahah, ijarah, musharakah) from legal documents
2. **Cortex Search on fatwa library** — Only demo indexing 200 Islamic jurisprudence rulings for semantic search
3. **ML.CLASSIFICATION for compliance risk scoring** — Scores Shariah non-compliance risk using contract terms and BNM guideline parameters
4. **Fatwa conflict detection** — Automatically surfaces conflicting DSN rulings across different time periods
5. **BNM guideline auto-validation** — Maps extracted contract terms directly to BNM regulatory requirements
6. **Malaysian Islamic finance context** — RM 2.3T sector with authentic Shariah governance terminology and BNM framework


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SHARIAH_COMPLIANCE.RAW.FINANCING_CONTRACTS` → 5000
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SHARIAH_COMPLIANCE.RAW.FATWA_LIBRARY` → 200
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SHARIAH_COMPLIANCE.RAW.COMPLIANCE_EVENTS` → 8000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SHARIAH_COMPLIANCE.ML.COMPLIANCE_RISK_RESULTS WHERE RISK_SCORE > 0.7` → >=12

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SHARIAH_COMPLIANCE.AI.CONTRACT_PARSE_RESULTS` → 5000
- [ ] `SELECT COUNT(*) FROM ISLAMIC_SHARIAH_COMPLIANCE.CURATED.FATWA_CONFLICT_MATRIX WHERE IS_CONFLICT = TRUE` → >=6

