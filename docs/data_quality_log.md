# Data Quality Log: Olist Raw Tables

**Version:** Final
**Audited on:** 19 Nov 2026
**Source:** `raw.*` tables in `data/olist.duckdb`
**Audit queries:** `sql/01_profiling.sql`

**Impact levels**

- **High:** changes a headline number (revenue, order count, customer count)
- **Medium:** distorts a secondary metric or a trend
- **Low:** very few rows, or no effect on any metric

## Table Readiness
- **Green:** No issue above Low. The table is usable as it is.
- **Amber:** The worst issue is Medium or Low to Medium. The table is usable once the documented rule is applied.
- **Red:** The table has a High impact issue. It must be fixed in the staging layer before it is joined or used.

| Table | Rating | Reason |
|-------|--------|--------|
| `order_payments` | Red | Orders are paid in parts, so joining without aggregating inflates revenue (issue 1) |
| `customers` | Red | `customer_id` is one per order, not per person; use `customer_unique_id` (issue 2) |
| `geolocation` | Red | 1 million rows for only 19,015 zip code prefixes; joining multiplies rows and inflates counts (issue 3) |
| `orders` | Amber | Patchy first and last months, delivered orders with no delivery date, and non-delivered orders carrying revenue (issues 4, 5, 17) |
| `order_items` | Amber | Revenue sits on non-delivered orders, and each unit is its own row (issues 17, 10) |
| `order_reviews` | Amber | `review_id` repeats across different orders; use `order_id` with `review_id` as the key (issue 7) |
| `products` | Amber | 610 products (1.85%) have no category or listing details (issue 6) |
| `category_translation` | Green | 2 categories (13 products) have no English translation; fixed with two manual entries (issue 18) |
| `sellers` | Green | No issues found; every check passed |

## Issues found

| # | Table | Issue | Rows affected | % | Business impact | Action |
|---|-------|-------|---------------|---|-----------------|--------|
| 1 | `order_payments` | Same `order_id` and `payment_type` pair repeats. Orders are paid in parts (for example a card plus several vouchers) | 1,091 pairs | n/a | **High.** Joining payments to orders and summing without aggregating inflates revenue | Aggregate to one row per order (and per type if needed) before joining |
| 2 | `customers` | `customer_id` is unique per order, not per person: 99,441 `customer_id` values belong to only 96,096 unique customers (`customer_unique_id`) | 3,345 extra IDs | 3.4% of `customer_id` values | **High.** Counting `customer_id` overstates the number of customers by about 3.5% and hides repeat purchases (only 3,345 orders, 3.4%, come from returning customers) | Use `customer_unique_id` for customer counts, retention and repeat-purchase metrics |
| 3 | `geolocation` | 1,000,163 rows for only 19,015 zip code prefixes, about 53 rows per prefix on average | 981,148 repeated rows | 98.1% of rows | **High.** Joining customers or sellers to geolocation on zip prefix multiplies rows many times over and inflates counts and revenue | Reduce to one row per zip code prefix in staging before joining |
| 4 | `orders` (date coverage) | No orders in Nov 2016, only 1 order in Dec 2016, then about 800 in Jan 2017 (Oct 2016 has 324). Sep and Oct 2018 are also patchy | 2 months empty or near empty at the start; 2 partial months at the end | n/a | **Medium.** Trend charts and growth rates will show false spikes and drops if these months are included | Start trend analysis from Jan 2017 and exclude the last two partial months (Sep and Oct 2018) |
| 5 | `orders` | 8 orders have status `delivered` but no delivery date. Items and review scores exist for all 8, so they are real sales. One of them also has no carrier date | 8 | 0.008% | **Medium.** Delivery-time and on-time metrics would be wrong if these rows are included | Keep in revenue; exclude from delivery-time metrics |
| 6 | `products` | `product_category_name`, `product_name_lenght`, `product_description_lenght` and `product_photos_qty` are missing together for the same products (up to 1.85% of products). Their sales are 179,535.28 of 13.59 million item revenue | 610 | 1.85% of products (610 of 32,951), 1.32% of item revenue | **Low to Medium.** These products appear without a category in category reports, which affects about 1.3% of revenue | Label category as `unknown` in staging; rename the `lenght` columns to `length` |
| 7 | `order_reviews` | `review_id` is not unique: 99,224 review rows but only 98,410 distinct `review_id` values. The same `review_id` can appear with different `order_id` values | 814 repeated rows | 0.82% | **Low to Medium.** Counting distinct `review_id` would undercount reviews; the true key is `review_id` with `order_id` | Use `order_id` plus `review_id` as the key; avoid counting reviews by `review_id` alone |
| 8 | `orders` | 775 orders have no rows in `order_items`: unavailable 603, canceled 164, created 5, invoiced 2, shipped 1. Only the shipped order is a real concern, and it dates from the start of the dataset (Oct 2016) | 775 | 0.78% | **Low.** No delivered orders affected, so revenue is unchanged | Exclude from revenue metrics; keep for funnel analysis |
| 9 | `orders` | Delivery-related dates are missing: `order_approved_at` (160), `order_delivered_carrier_date` (1,783), `order_delivered_customer_date` (2,965) | 160 / 1,783 / 2,965 | 0.16% / 1.79% / 2.98% | **Low.** Expected for orders that were canceled or not yet delivered | Keep the nulls; filter them out only in delivery-time metrics |
| 10 | `order_items` | The same product appears more than once within an order (7,088 `order_id` and `product_id` pairs). Each unit has its own row | 7,088 pairs | n/a | **Low.** Not an error, but quantity must be derived by counting rows | Count rows for units; use `count(DISTINCT product_id)` for product variety |
| 11 | `orders` and `order_reviews` | 768 orders have no review | 768 | 0.77% | **Low.** Not every customer leaves a review | Treat missing reviews as "no review", not as a score of zero |
| 12 | `order_items` | 383 items have freight of 0, most likely free shipping | 383 | 0.34% | **Low.** Average freight cost is pulled down if these are included without noting them | Keep the rows; flag free shipping when analysing freight |
| 13 | `order_payments` and `order_items` | Customer paid at least 1 less than items plus freight | 18 | 0.018% | **Low.** Item-based revenue is overstated by about 199 in total | Use `payment_value` for cash received and item `price` for product revenue; do not mix them |
| 14 | `order_payments` and `order_items` | Customer paid at least 1 more than items plus freight. 229 of the 232 orders (98.7%) were paid in more than 1 instalment, and the 40 largest gaps (up to 182.81) all have 6 to 24 instalments with the extra growing with the instalment count (about 13% at 10 instalments, 24% at 20, 29% at 24). The cause is almost certainly instalment interest; the other 3 orders have no instalments and remain unexplained | 232 | 0.24% | **Low to Medium.** Payment-based revenue is higher than item-based revenue for these orders, because it includes financing charges | Define revenue from item `price` in the metric dictionary; treat the extra as financing, not product revenue |
| 15 | `order_items` and `order_payments` | 1 delivered order (items worth 143.46) has no payment record | 1 | 0.001% | **Low.** Payment-based revenue would miss 143.46 | Flag in staging; compute revenue from item `price`, not from payments |
| 16 | `order_payments` | 9 payment rows have a value of 0: 6 zero-value voucher lines (5 orders) and 3 rows with type `not_defined` (3 orders, one payment line each). All 3 `not_defined` orders are canceled | 9 rows (8 orders) | 0.008% of orders | **Low.** No money involved; the `not_defined` rows are placeholders for canceled orders | Drop zero-value rows from payment metrics; treat `not_defined` as a placeholder for canceled orders and exclude it from payment-type reporting |
| 17 | `orders` and `order_items` | Items and revenue sit on orders that are not delivered. Of 98,666 orders with items, 2,188 are not delivered: shipped 1,106, canceled 461, invoiced 312, processing 301, unavailable 6, approved 2. Their item revenue is about 370,146 of 13.59 million, of which canceled orders carry 95,235 | 2,188 orders (2,453 item rows) | 2.2% of orders, 2.72% of item revenue | **Medium.** Revenue and order counts are overstated by about 2.7% if they are not filtered by status | Base revenue, order counts and delivery metrics on `delivered` orders only; keep shipped, invoiced and processing for pipeline views and exclude canceled and unavailable |
| 18 | `products` and `category_translation` | 2 product categories have no English translation: `portateis_cozinha_e_preparadores_de_alimentos` (10 products) and `pc_gamer` (3 products) | 13 products | 0.04% of products | **Low.** These categories show with no English label in category reports; an inner join to the translation table would drop the products | Add the two translations manually in staging; join with `LEFT JOIN` |
| 19 | `order_payments` | 2 credit card payment rows have 0 instalments, which is not logical (a single payment counts as 1) | 2 | 0.002% of payment rows | **Low.** Instalment statistics (average instalments, share paid in instalments) would be slightly off | Treat 0 instalments as 1 in staging |

## Checks passed

| Table or area | Result |
|---------------|--------|
| Table links (orphan checks) | No orphan rows: items link to orders, products and sellers; orders link to customers; payments and reviews link to orders |
| `category_translation` | No nulls, no duplicates |
| `geolocation` | No nulls (repeats are logged as issue 3) |
| `sellers` | No nulls, no duplicates. `seller_id` is unique |
| `customers` | No nulls, no duplicate rows (but see issue 2 on `customer_id` versus `customer_unique_id`) |
| `order_reviews` | Nulls exist only in the comment title and comment message columns. These are optional, so nothing to worry about |
| `order_reviews` | All review scores are between 1 and 5 |
| `orders` | `order_id` is unique |
| `orders` dates | No order is delivered before it was purchased (0 rows) |
| `orders` status | 8 statuses, none unexpected; 96,478 of 99,441 orders (97%) are `delivered` |
| `order_items` | The pair `order_id` and `order_item_id` is unique |
| `order_items` price | Minimum 0.85, maximum 6,735.00; no zero or negative prices |
| `products` | `product_id` is unique |
| Payments versus items | 98,415 of 98,666 orders (99.7%) reconcile between items plus freight and payments within 1 currency unit |
| Category translation | All other product categories have an English translation (exceptions are logged as issue 18) |
| `order_payments` types | Only 5 payment types exist: credit_card (76,795 rows), boleto (19,784), voucher (5,775), debit_card (1,529) and not_defined (3, see issue 16) |