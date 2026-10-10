# Islamic Bank Shariah Review Operations

**Malaysia - Islamic Bank Shariah Review**
Use case: Documentation exceptions, escalation to the Shariah committee and review process controls

> Shariah review operations for 40 financing portfolios at a fictional Malaysian Islamic bank across 5 cities: dynamic tables, a holdout-evaluated escalation classifier, an exception-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile contracts reviewed, documentation exceptions, escalations, rectification SLA breaches and branch process review compliance from RAW portfolio data, with checks in `run_core.py`
- **Escalation classification** gives a holdout-evaluated next-7-day probability per portfolio
- **Exception forecast** projects 14 days of bank-wide exception volume with prediction intervals, for review team staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live reviews**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.PORTFOLIOS` (40 rows) |
| Fact table | `RAW.PORTFOLIO_DAILY` (3,600 portfolio-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `EXCEPTION_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.ESCALATION_RISK_SCORES`, `ML.ESCALATION_RISK_HOLDOUT_METRICS`, `ML.EXCEPTION_FORECAST`, `ML.DOC_REJECT_ANOMALIES` |

Cities: Kuala Lumpur, George Town, Johor Bahru, Kota Kinabalu, Kuching (MYR).
Financing products: Personal financing-i tawarruq, SME financing-i murabahah, Home financing-i musharakah mutanaqisah, Vehicle financing-i ijarah, Trade financing-i wakalah.

Product notes, for the presenter: tawarruq is a sequence of commodity purchase and sale transactions that provides the customer with cash; murabahah is a sale at cost plus a disclosed margin; musharakah mutanaqisah is a diminishing partnership in which the customer buys out the bank's share over time; ijarah is a lease; wakalah is an agency arrangement. The demo describes review operations only: the bank's Shariah committee decides escalated matters, and the demo makes no Shariah, religious or regulatory rulings.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Clean Review Rate | 99.93% |
| Documentation Exceptions | 531 |
| Escalated to Shariah Committee | 138 |
| Escalation Rate | 26.0% |
| Rectification SLA Breaches | 65 |
| Reviewed Value (MYR M) | 80,328 |
| Contracts Reviewed | 743,308 |
| Process Review Compliance | 82.8% |
| Portfolios Monitored | 40 |
| Contract File Coverage | 61.1% |
| Contract Documents Pending | 13 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily documentation exceptions against escalations, exceptions and escalations by reason, portfolio table
2. Predictive: holdout metrics, risk bands, 14-day exception forecast, document rejection rate anomalies
3. Controls: process review compliance, contract file coverage and pending documents, review compliance against escalated exceptions, then generate the action memo
4. Live Reviews: run `CALL APP.SIMULATE_REVIEWS(20)` (Snowflake only) or `python aws/publish_reviews.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_EXCEPTION_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.93% of contracts reviewed pass without a documentation exception; the 531 exceptions are where review time goes, and 26.0% of them are escalated to the Shariah committee.
- Execution sequence not evidenced and customer acknowledgement missing produce the most escalations (39 and 37, from 102 and 143 exceptions). Document system outages hit every portfolio in a city at once and are always rectified without escalation.
- The risk model is evaluated on a time-based holdout: precision 0.29 and recall 0.19 at 0.5, against a 0.20 base rate. Present it as triage for the review team, not a verdict.
- Document system outages are excluded from model training, because they are not portfolio-driven.
- The exception reasons are operational documentation checks. Whether a matter is Shariah compliant is for the bank's Shariah committee; the demo makes no such determination.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
