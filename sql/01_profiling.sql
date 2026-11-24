-- 01_profiling.sql
-- Purpose: audit the raw Olist tables before modelling.
-- Run: duckdb -readonly data/olist.duckdb < sql/01_profiling.sql
-- Objective 1: to understand the shape of the data, identify null values, and check for duplicates.
-- Shape: 1. Orders
Describe raw.orders;
Select count (*) As orders_rows from raw.orders;
Summarize raw.orders; -- low null percentage, only order_approved (0.16%), order_delivered_carrier_date(1.79%), Order_delivered_customer_date (2.98%)
SELECT
count(*) AS total_rows,
count(*) - count(order_approved_at) AS missing_approved_at,
count(*) - count(order_delivered_customer_date) AS missing_delivered_date,
count(*) - count(order_delivered_carrier_date) AS missing_delivered_carrier_date
FROM raw.orders;
-- Shape: 2. Order Items 
Describe raw.order_items;
Select count (*) As order_items_rows from raw.order_items;
Summarize raw.order_items;
-- No null values identified in order_items table, but let's check for duplicates

Select order_id, product_id, count(*) as duplicate_count
from raw.order_items
group by order_id, product_id
having count(*) > 1; -- 7088 duplicate values 
-- Shape: 3. Order Payments
Describe raw.order_payments;
Select count (*) As order_payments_rows from raw.order_payments;
Summarize raw.order_payments;
-- no Null values identified in order_payments table, but let's check for duplicates
Select order_id, payment_type, count(*) as duplicate_count
from raw.order_payments
group by order_id, payment_type
having count(*) > 1; -- 1091 duplicates for order_id, payment_type pair

Select order_id, payment_type, payment_sequential, payment_value, payment_installments
From raw.order_payments
Where order_id = 'dc96a12713fb7cbfd8feac4ab0b8f2a2';

SELECT sum(price) AS items_price, sum(freight_value) AS freight,
       sum(price) + sum(freight_value) AS items_total
FROM raw.order_items
WHERE order_id = 'dc96a12713fb7cbfd8feac4ab0b8f2a2'; -- total price = price + Freight_value

Select sum(payment_value) as item_price
FROM raw.order_payments
WHERE order_id = 'dc96a12713fb7cbfd8feac4ab0b8f2a2'; -- Checking total price paid for an order

-- Shape: 4. Order Reviews
Describe raw.order_reviews;
Select count (*) As order_reviews_rows from raw.order_reviews;
Summarize raw.order_reviews;
-- Null values are present in the order_reviews table but they are limited to comments title and comments message. Also no need to check duplicate here
-- Comments title and Comments message have max null values

-- Shape: 5. Customers
Describe raw.customers;
Select count (*) As customers_rows from raw.customers;
Summarize raw.customers;
-- no null values

Select customer_id, count(*) as duplicate_count
FROM raw.customers
Group By customer_ID
Having count(*)>1; -- no duplicate

-- Shape: 6. Products
Describe raw.products;
Select count (*) As products_rows from raw.products;
Summarize raw.products;
-- product_category_name, product_name_lenght, product_description_lenght, product_photos_qty have max null values at 1.85%

-- Shape: 7. Sellers
Describe raw.sellers;
Select count (*) As sellers_rows from raw.sellers;
Summarize raw.sellers;
-- No null values identified in sellers table, but let's check for duplicates
Select seller_id, count(*) as duplicate_count
from raw.sellers
group by seller_id
having count(*) > 1;
-- No duplicates found in sellers table on seller_id

-- Shape: 8. Geolocation
Describe raw.geolocation;
Select count (*) As geolocation_rows from raw.geolocation;
Summarize raw.geolocation;
-- No null values identified in geolocation table, but let's check for duplicates
Select geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, count(*) as duplicate_count
from raw.geolocation
group by geolocation_zip_code_prefix, geolocation_lat, geolocation_lng
having count(*) > 1;
-- 1,000,163 rows for 19,015 zip prefixes: heavy repeats

-- Shape: 9. Category Translation
Describe raw.category_translation;
Select count (*) As category_translation_rows from raw.category_translation;
Summarize raw.category_translation;
-- No null values identified in category_translation table, but let's check for duplicates
Select product_category_name_english, count(*) as duplicate_count
from raw.category_translation
group by product_category_name_english
having count(*) > 1;
-- no duplication
Show all tables;

-- Objective 2: Check that IDs can be trusted
select order_id, count(*) as count 
from raw.orders 
group by order_id
having count(*) > 1; -- no duplicates in order IDs
Select customer_id, customer_unique_id, count(*) as count
from raw.customers
group by customer_id, customer_unique_id
having count(*) > 1; -- no duplicates in customer IDs

Select order_id, order_item_id, count(*) as count
from raw.order_items
group by order_id, order_item_id
having count(*) > 1; -- no duplicates in order_item IDs
select review_id, count(*) as count
from raw.order_reviews
group by review_id
having count(*) > 1; -- duplicates in review_ids, same review_id can have different order_ids
select seller_id, count(*) as count
from raw.sellers
group by seller_id
having count(*) > 1; -- Seller IDs are unique
select product_id, count(*) as count
from raw.products
group by product_id
having count(*) > 1; -- Product IDs are unique
select geolocation_zip_code_prefix, count(*) as count
from raw.geolocation
group by geolocation_zip_code_prefix
having count(*) > 1 
ORDER BY count DESC; -- Repeats maximum 3 times

-- Objective 3: Check that tables connect
-- Test Left Join Links
-- Items to Orders
Select count(*) as orphan_order_items
from raw.order_items
LEFT JOIN raw.orders ON raw.order_items.order_id = raw.orders.order_id
WHERE raw.orders.order_id IS NULL; -- There are no orphan order_items, all order_items have a corresponding order
-- items to Products
Select count(*) as orphan_order_items_products
from raw.order_items
LEFT JOIN raw.products ON raw.order_items.product_id = raw.products.product_id
WHERE raw.products.product_id IS NULL; -- There are no orphan order_items, all order_items have a corresponding product
-- items to sellers
Select count(*) as orphan_order_items_sellers
from raw.order_items
LEFT JOIN raw.sellers ON raw.order_items.seller_id = raw.sellers.seller_id
WHERE raw.sellers.seller_id IS NULL; -- There are no orphan order_items, all order_items have a corresponding seller
-- orders to customers
Select count(*) as orphan_orders_customers
from raw.orders 
LEFT JOIN raw.customers
ON raw.orders.customer_id = raw.customers.customer_id
WHERE raw.customers.customer_id IS NULL; -- There are no orphan orders, all orders have a corresponding customer
-- Reviews to Order
SELECT count(*) AS orphan_reviews
FROM raw.order_reviews
LEFT JOIN raw.orders ON raw.order_reviews.order_id = raw.orders.order_id
WHERE raw.orders.order_id IS NULL; -- 0 means every review belongs to an order. There are 768 Orphan order reviews, meaning that 768 orders have no corresponding review. This is expected as not all customers leave reviews.
-- payments to orders
SELECT count(*) AS orphan_payments
FROM raw.order_payments
LEFT JOIN raw.orders ON raw.order_payments.order_id = raw.orders.order_id
WHERE raw.orders.order_id IS NULL; -- 0 means every payment belongs to an order

-- Reverse check to see child entry in parent: Order to items 
Select order_status, count(*) as orders_without_items
from raw.orders
LEFT JOIN raw.order_items ON raw.orders.order_id = raw.order_items.order_id
WHERE raw.order_items.order_id IS NULL
GROUP BY raw.orders.order_status
ORDER BY orders_without_items DESC; 

Select orders.order_id, orders.order_status, orders.order_purchase_timestamp
FROM raw.orders
LEFT JOIN raw.order_items ON raw.orders.order_id = raw.order_items.order_id
WHERE raw.order_items.order_item_id IS NULL AND raw.orders.order_status IN ('created', 'invoiced', 'shipped')
ORDER BY orders.order_purchase_timestamp; 
-- 775 entries are orders without items of which unavailable orders are 603, cancelled 164, created 5, invoiced 2, shipped 1. of 8 created, invoiced and shipped only shipped 1 is problem but it was from the starting point of database creation. 

-- products to items
Select count (*) as missing_products_items
from raw.products
LEFT JOIN raw.order_items ON raw.products.product_id = raw.order_items.product_id
WHERE raw.order_items.product_id is NULL; -- No missing products in order_items

-- sellers to items
Select count(*) as missing_selling_items
FROM raw.sellers
LEFT JOIN raw.order_items ON raw.sellers.seller_id = raw.order_items.seller_id
WHERE raw.order_items.seller_id IS NULL; -- No missing sellers

-- customers to orders
Select count (*) as missing_customers_from_orders
FROM raw.customers
LEFT JOIN raw.orders ON raw.customers.customer_id = raw.orders.customer_id
WHERE raw.orders.customer_id IS NULL; -- No missing customer ID in orders

-- orders to reviews
Select count(*) as missing_orders_from_reviews
FROM raw.orders
LEFT JOIN raw.order_reviews ON raw.orders.order_id = raw.order_reviews.order_id
WHERE raw.orders.order_id IS NULL; -- No missing orders from reviews table

-- Objective 4: Spot suspicious values
-- List the order statuses with counts
Select order_status, count(*) as order_status_count
from raw.orders
group by order_status
order by order_status_count desc;

-- Check date logic: delivered before purchased, or delivery dates missing for delivered orders
SELECT order_id, order_purchase_timestamp, order_delivered_customer_date
FROM raw.orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

Select order_id, order_status, order_purchase_timestamp, order_delivered_customer_date
From raw.orders
where order_delivered_customer_date is NULL and order_status = 'delivered'
ORDER BY order_id ASC; -- Investigate since there are 8 orders without delivery date but status is delivered
-- look at the other date columns for the same orders
Select order_id, order_purchase_timestamp,order_approved_at,order_delivered_carrier_date, order_estimated_delivery_date
FROM raw.orders
WHERE order_delivered_customer_date is NULL and order_status = 'delivered'
ORDER BY order_purchase_timestamp DESC; -- only one case where carrier delivery date is also missing
-- check whether these orders look like real, completed sales
Select raw.orders.order_id, count(DISTINCT order_item_id) AS items, max(review_score) AS review_score
FROM raw.orders
LEFT JOIN raw.order_items ON raw.orders.order_id = raw.order_items.order_id
LEFT JOIN raw.order_reviews ON raw.orders.order_id = raw.order_reviews.order_id 
WHERE raw.orders.order_delivered_customer_date is NULL and raw.orders.order_status = 'delivered'
GROUP BY raw.orders.order_id; -- items and Review score are both present for all 8 orders, so they look like real sales. The one order with missing carrier delivery date is also a real sale.

-- Check min and max prices and frieght_value, and count zeros
Select min(price) as min_price, max(price) as max_price, min(freight_value) as min_freight_value, max(freight_value) as max_freight_value
FROM raw.order_items;
Select count(*) as zero_price_count, count(*) as zero_freight_count
FROM raw.order_items
WHERE price = 0 OR freight_value = 0; -- zeros are 383 in both 

SELECT count(*) FILTER (WHERE price = 0) AS zero_price,
       count(*) FILTER (WHERE freight_value = 0) AS zero_freight,
       count(*) FILTER (WHERE price = 0 OR freight_value = 0) AS either
FROM raw.order_items;

SELECT count(*) AS scores_out_of_range
FROM raw.order_reviews
WHERE review_score NOT BETWEEN 1 AND 5 OR review_score IS NULL; -- 0 means all scores are 1 to 5. All scores in between 1 and 5, no suspicious values 

-- Check the first and last purchase dates, and look for gaps by month
SELECT CAST(order_purchase_timestamp AS DATE) AS purchase_date,
       count(*) AS purchase_count
FROM raw.orders
GROUP BY purchase_date
ORDER BY purchase_date ASC;-- Sep 04, 2016 as first and Oct 17 2018 as last date

Select date_trunc('month', order_purchase_timestamp) AS purchase_month,
       count(*) AS purchase_count
       FROM raw.orders
GROUP BY purchase_month
ORDER BY purchase_month ASC; -- There is one month gap from Nov 2016 when there were no orders and dec only has 1 order. Point to note, Oct 2016 is 324 and jan 2017 has 800
-- Also, end months Sep and Oct 2018 are patchy

--Some more checks
-- Payment reconcile with items: Compare sum(payment_value) with sum(price + freight_value) per order.
With items AS (Select order_id, sum(price+freight_value) AS items_total FROM raw.order_items GROUP BY order_id),
payments AS (Select order_id, sum(payment_value) AS total_paid FROM raw.order_payments GROUP BY order_id) 
SELECT count(*) AS orders_checked,
       count(*) FILTER (WHERE payments.total_paid IS NULL) AS no_payment_row,
       count(*) FILTER (WHERE items.items_total - payments.total_paid > 0) AS any_shortfall,
       count(*) FILTER (WHERE items.items_total - payments.total_paid >= 1) AS shortfall_1_or_more,
       count(*) FILTER (WHERE payments.total_paid - items.items_total >= 1) AS overpaid_1_or_more
FROM items
LEFT JOIN payments ON items.order_id = payments.order_id;

-- Find the unpaid order
SELECT i.order_id, i.items_total, o.order_status
FROM (SELECT order_id, sum(price + freight_value) AS items_total
      FROM raw.order_items GROUP BY order_id) AS i
JOIN raw.orders AS o ON i.order_id = o.order_id
WHERE i.order_id NOT IN (SELECT order_id FROM raw.order_payments);

-- Test the instalment-interest idea for the 232
With items AS (Select order_id, sum(price + freight_value) as items_total FROM raw.order_items GROUP BY order_id),
payments AS (Select order_id, sum(payment_value) as total_paid,max(payment_installments) as max_installments FROM raw.order_payments GROUP BY order_ID)
Select items.order_id, items.items_total, payments.total_paid, payments.max_installments, round(payments.total_paid - items.items_total, 2) AS extra_paid
FROM items
Join payments on items.order_id = payments.order_id
WHERE payments.total_paid - items.items_total >= 1
ORDER BY extra_paid DESC
LIMIT 40;

-- Payment Oddities: Look for payment_value = 0 or a payment type like not_defined
SELECT order_id, payment_sequential, payment_type, payment_value, payment_installments
FROM raw.order_payments
WHERE payment_value <= 0 OR payment_value IS NULL
ORDER BY payment_value;

SELECT payment_type, count(*) AS payment_rows
FROM raw.order_payments
WHERE payment_type = 'not_defined'
GROUP BY payment_type
ORDER BY payment_rows DESC;

SELECT payment_type, payment_installments, count(*) AS payment_rows
FROM raw.order_payments
WHERE payment_installments < 1
GROUP BY payment_type, payment_installments;

SELECT o.order_id, o.order_status, i.items_total, p.total_paid
FROM raw.orders AS o
LEFT JOIN (SELECT order_id, sum(price + freight_value) AS items_total
           FROM raw.order_items GROUP BY order_id) AS i ON o.order_id = i.order_id
LEFT JOIN (SELECT order_id, sum(payment_value) AS total_paid
           FROM raw.order_payments GROUP BY order_id) AS p ON o.order_id = p.order_id
WHERE o.order_id IN ('4637ca194b6387e2d538dc89b124b0ee',
                     '00b1cb0320190ca0daa2c88b35206009',
                     'c8c528189310eaa44a745b8d9d26908b');

-- Items on cancelled orders. If cancelled orders have items, revenue is overstated unless you filter by status.
Select raw.orders.order_id, raw.orders.order_status, raw.order_items.order_item_id, raw.order_items.product_id
FROM raw.orders
JOIN raw.order_items ON raw.orders.order_id = raw.order_items.order_id
WHERE raw.orders.order_status = 'canceled';

-- Find revenue and item counts by status
Select Distinct o.order_status, 
COUNT (Distinct o.order_id) AS orders_with_items,
count(*) AS items_rows,
round (sum(i.price),2) AS item_revenue
FROM raw.orders as o
JOIN raw.order_items as i ON o.order_id = i.order_id
GROUP BY o.order_status
ORDER BY item_revenue DESC; 

-- Category translation coverage. Check for category names in products that have no row in category_translation
Select count (Distinct product_category_name), count(Distinct product_category_name_english)
FROM raw.category_translation;

Select p.product_category_name, count(*) AS products
FROM raw.products as p
LEFT JOIN raw.category_translation as i ON p.product_category_name = i.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND i.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY products DESC;
-- 2 categories (13 products) have no English translation

-- 5. Numbers for the data quality log
-- Issue 2: customers
SELECT count(DISTINCT customer_id) AS customer_ids,
       count(DISTINCT customer_unique_id) AS unique_customers
FROM raw.customers;

-- Issue 3: geolocation (check the column name with DESCRIBE raw.geolocation; if it differs, adjust)
SELECT count(*) AS geolocation_rows,
       count(DISTINCT geolocation_zip_code_prefix) AS zip_prefixes
FROM raw.geolocation;

SELECT round(sum(i.price) FILTER (WHERE p.product_category_name IS NULL), 2) AS revenue_no_category,
       round(sum(i.price), 2) AS revenue_total,
       round(100.0 * sum(i.price) FILTER (WHERE p.product_category_name IS NULL) / sum(i.price), 2) AS pct_of_revenue
FROM raw.order_items AS i
JOIN raw.products AS p ON i.product_id = p.product_id;

-- Issue 7: repeated review_id values
SELECT count(*) AS review_rows,
       count(DISTINCT review_id) AS distinct_review_ids
FROM raw.order_reviews;

-- Issue 9: exact null counts in orders
SELECT count(*) FILTER (WHERE order_approved_at IS NULL) AS approved_null,
       count(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS carrier_null,
       count(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS customer_null
FROM raw.orders;

WITH items AS (
    SELECT order_id, sum(price + freight_value) AS items_total
    FROM raw.order_items GROUP BY order_id
),
payments AS (
    SELECT order_id, sum(payment_value) AS total_paid,
           max(payment_installments) AS max_installments
    FROM raw.order_payments GROUP BY order_id
)
SELECT count(*) AS overpaid_orders,
       count(*) FILTER (WHERE payments.max_installments > 1) AS with_instalments,
       count(*) FILTER (WHERE payments.max_installments <= 1) AS without_instalments
FROM items
JOIN payments ON items.order_id = payments.order_id
WHERE payments.total_paid - items.items_total >= 1;

-- Payment types and instalments below 1
SELECT payment_type, count(*) AS payment_rows
FROM raw.order_payments
GROUP BY payment_type
ORDER BY payment_rows DESC;

SELECT payment_type, payment_installments, count(*) AS payment_rows
FROM raw.order_payments
WHERE payment_installments < 1
GROUP BY payment_type, payment_installments;

SELECT count(*) AS products_total,
       count(*) FILTER (WHERE product_category_name IS NULL) AS no_category
FROM raw.products;