-- Purpose: load the nine untouched Olist CSV files into DuckDB, schema "raw".
-- Run from the project root: duckdb data/olist.duckdb < sql/00_load_raw.sql
CREATE SCHEMA IF NOT EXISTS raw;
create or replace table raw.customers as select * from read_csv('data/raw/olist_customers_dataset.csv');
create or replace table raw.geolocation as select * from read_csv('data/raw/olist_geolocation_dataset.csv');
CREATE OR REPLACE TABLE raw.order_items AS SELECT * FROM read_csv('data/raw/olist_order_items_dataset.csv');
CREATE OR REPLACE TABLE raw.order_payments AS SELECT * FROM read_csv('data/raw/olist_order_payments_dataset.csv');
CREATE OR REPLACE TABLE raw.order_reviews AS SELECT * FROM read_csv('data/raw/olist_order_reviews_dataset.csv');
CREATE OR REPLACE TABLE raw.orders AS SELECT * FROM read_csv('data/raw/olist_orders_dataset.csv');
CREATE OR REPLACE TABLE raw.products AS SELECT * FROM read_csv('data/raw/olist_products_dataset.csv');
CREATE OR REPLACE TABLE raw.sellers AS SELECT * FROM read_csv('data/raw/olist_sellers_dataset.csv');
CREATE OR REPLACE TABLE raw.category_translation AS SELECT * FROM read_csv('data/raw/product_category_name_translation.csv');
-- Row count per table: compare with the Kaggle page
Select 'customers' as table_name, count(*) as row_count from raw.customers
union all select 'geolocation' as table_name, count(*) as row_count from raw.geolocation
union all select 'order_items' as table_name, count(*) as row_count from raw.order_items
union all select 'order_payments' as table_name, count(*) as row_count from raw.order_payments
union all select 'order_reviews' as table_name, count(*) as row_count from raw.order_reviews
union all select 'orders' as table_name, count(*) as row_count from raw.orders
union all select 'products' as table_name, count(*) as row_count from raw.products
union all select 'sellers' as table_name, count(*) as row_count from raw.sellers
union all select 'category_translation' as table_name, count(*) as row_count from raw.category_translation