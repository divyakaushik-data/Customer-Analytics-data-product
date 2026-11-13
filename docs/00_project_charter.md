# Project Charter: Customer Analytics Data Product

**Owner:** Divya Kaushik  |  **Status:** Draft v1  |  **Date:** 16 Nov 2026

## Purpose
Show how I would build a customer analytics function across a B2C marketplace (Olist) and a B2B sales team (Maven CRM): a governed data model, trusted metrics, dashboards, predictive models and an AI roadmap.

## Audience
A hiring manager or business head, founders, CEO, Chief AI officer who wants evidence that I can build, govern and lead analytics, not only commission it.

## Business questions
1. Where is delivery performance hurting customer satisfaction, and what does it cost?
2. Do customers come back, and what separates repeat buyers from one-time buyers?
3. Which sellers and product categories drive revenue, and which drag down quality?
4. Which orders are at risk of a bad review, and what is the value of acting early?
5. What will order demand look like over the next 8 to 12 weeks?
6. Where does the B2B sales pipeline leak: by stage, product and sales agent?
7. Which customer-experience themes in review text matter most?

## KPIs (each gets a precise definition in docs/metric_dictionary.md later)
| Area | KPI |
| --- | --- |
| Growth | Revenue, orders, average order value |
| Delivery | On-time delivery %, average delivery days |
| Satisfaction | Average review score, % of 1-2 star reviews |
| Retention | Repeat purchase rate |
| B2B pipeline | Win rate, open pipeline value, average sales cycle days |

## Scope
**In scope:** the Olist and Maven datasets, a dbt star schema with tests, SQL and Python analysis, a Tableau Public dashboard, a risk model, a demand forecast, a GenAI review-theme experiment, governance documents and an analytics strategy.

**Out of scope:** real-time pipelines, production deployment, cloud infrastructure, and causal claims beyond what the data supports.

## Data and limits
Olist is anonymised 2016-18 Brazilian marketplace data (about 100k orders). Maven is a fictional B2B pipeline. Findings describe these datasets and do not generalise to any real company.

## Deliverables
Monthly releases v0.1 to v1.0 in this repo, with a README that reads as an executive summary.

## Definition of done
A reader who only opens the README can name the five most useful findings, trust the numbers, and see how I would run the function.