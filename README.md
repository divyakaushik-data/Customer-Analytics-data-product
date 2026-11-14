# Customer Analytics Data Product

> How I would build a customer analytics function across a B2C marketplace and a B2B sales team.

**Status:** in progress. Built in public, one monthly release at a time.

## Business questions
See [docs/00_project_charter.md](docs/00_project_charter.md).

## Key findings
_Added as the project grows._

## Architecture
_Raw data, then dbt staging and marts, then notebooks and Tableau. Diagram coming in month 2._

## How to reproduce
## How to reproduce

1. Clone the repo and create the environment (Python 3.12 and [uv](https://docs.astral.sh/uv/)):

```bash
git clone https://github.com/divyakaushik-data/customer-analytics-data-product.git
cd customer-analytics-data-product
uv venv --python 3.12
source .venv/bin/activate
uv pip install -r requirements.txt
```

2. Download the Olist data (needs a free [Kaggle API token](https://www.kaggle.com/settings) saved in `~/.kaggle/access_token`):

```bash
kaggle datasets download -d olistbr/brazilian-ecommerce -p data/raw --unzip
```

3. Load the raw tables into DuckDB and print row counts:

```bash
duckdb data/olist.duckdb < sql/00_load_raw.sql
```
Raw data and the database file stay on your machine. They are listed in `.gitignore` and never committed.

## Data sources
- [Olist Brazilian E-Commerce (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- [Maven CRM Sales Opportunities](https://mavenanalytics.io/data-playground/crm-sales-opportunities)