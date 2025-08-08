# Case Study #2 — Pizza Runner

**Dataset (assumed tables)**
- `customer_orders(order_id, customer_id, order_datetime, delivery_datetime, total_price, payment_type, order_status, rating, promised_delivery_datetime)`
- `order_items(order_item_id, order_id, pizza_id, quantity, item_price)`
- `pizzas(pizza_id, pizza_name, size, base_price)`
- `runners(runner_id, name)`
- `runner_orders(runner_order_id, runner_id, order_id, pickup_time, dropoff_time)`
- `ingredients(ingredient_id, ingredient_name, cost_per_unit)`
- `pizza_ingredients(pizza_id, ingredient_id, qty_required)`
- `customers(customer_id, join_date, city, signup_channel)`
- `price_changes(pizza_id, change_date, old_price, new_price)`

> All queries are written for MySQL 8+. Adjust names if your dataset uses different column names.

---

## Section A — Pizza Metrics

### A1. Total number of pizzas ordered
**Question:** How many pizzas have been ordered in total?
**SQL**
```sql
SELECT SUM(quantity) AS total_pizzas_ordered FROM order_items;
```
**Explanation:** Sum the `quantity` column in `order_items` since each row indicates how many of a pizza were ordered.


### A2. Total revenue (completed orders)
**Question:** What is the total revenue from completed orders?
**SQL**
```sql
SELECT ROUND(SUM(total_price),2) AS total_revenue
FROM customer_orders
WHERE order_status = 'completed';
```
**Explanation:** Sum `total_price` filtering for completed orders to exclude cancellations/refunds.


### A3. Average order value (AOV)
**Question:** What is the average order value?
**SQL**
```sql
SELECT ROUND(AVG(total_price),2) AS avg_order_value
FROM customer_orders
WHERE order_status = 'completed';
```
**Explanation:** Average of order totals for completed orders — useful KPI for revenue per order.


### A4. Top 10 pizzas by quantity sold
**Question:** Which pizzas sell the most by quantity?
**SQL**
```sql
SELECT p.pizza_id, p.pizza_name, SUM(oi.quantity) AS qty_sold
FROM order_items oi
JOIN pizzas p ON oi.pizza_id = p.pizza_id
JOIN customer_orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY p.pizza_id, p.pizza_name
ORDER BY qty_sold DESC
LIMIT 10;
```
**Explanation:** Join order items with pizzas and orders, sum quantities per pizza, order descending.


### A5. Monthly orders trend
**Question:** How do orders change month-over-month?
**SQL**
```sql
SELECT DATE_FORMAT(order_datetime, '%Y-%m') AS year_month, COUNT(*) AS orders_count
FROM customer_orders
WHERE order_status = 'completed'
GROUP BY year_month
ORDER BY year_month;
```
**Explanation:** Group completed orders by year-month to detect seasonality.


---

## Section B — Runner and Customer Experience

### B1. Average delivery time (minutes)
**Question:** What is the average delivery time (from pickup to dropoff) in minutes?
**SQL**
```sql
SELECT ROUND(AVG(TIMESTAMPDIFF(MINUTE, pickup_time, dropoff_time)),2) AS avg_delivery_minutes
FROM runner_orders ro
JOIN customer_orders o ON ro.order_id = o.order_id
WHERE o.order_status = 'completed';
```
**Explanation:** Use TIMESTAMPDIFF to compute minutes between pickup and dropoff, then average.


### B2. Delivery time distribution (buckets)
**Question:** How are deliveries distributed across time buckets (0–10, 11–20, etc.)?
**SQL**
```sql
SELECT CASE
         WHEN diff <= 10 THEN '0-10'
         WHEN diff <= 20 THEN '11-20'
         WHEN diff <= 30 THEN '21-30'
         WHEN diff <= 45 THEN '31-45'
         ELSE '46+' END AS bucket,
       COUNT(*) AS orders_count
FROM (
  SELECT TIMESTAMPDIFF(MINUTE, pickup_time, dropoff_time) AS diff
  FROM runner_orders ro
  JOIN customer_orders o ON ro.order_id = o.order_id
  WHERE o.order_status = 'completed'
) t
GROUP BY bucket
ORDER BY FIELD(bucket,'0-10','11-20','21-30','31-45','46+');
```
**Explanation:** Bucket delivery minutes for a frequency distribution to identify late deliveries.


### B3. Runner performance: average deliveries per runner in a month
**Question:** How many deliveries does each runner average per month?
**SQL**
```sql
SELECT ro.runner_id, r.name,
       COUNT(DISTINCT ro.order_id) AS deliveries_count,
       ROUND(COUNT(DISTINCT ro.order_id)/NULLIF(COUNT(DISTINCT DATE_FORMAT(ro.pickup_time, '%Y-%m')),0),2) AS avg_deliveries_per_month
FROM runner_orders ro
JOIN runners r ON ro.runner_id = r.runner_id
JOIN customer_orders o ON ro.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY ro.runner_id, r.name
ORDER BY deliveries_count DESC;
```
**Explanation:** Count unique orders per runner and divide by number of months they worked (approx) for per-month rate.


### B4. Percentage of late deliveries
**Question:** What percentage of deliveries were late (dropoff_time > promised_delivery_datetime)?
**SQL**
```sql
SELECT ROUND(100.0 * SUM(CASE WHEN ro.dropoff_time > o.promised_delivery_datetime THEN 1 ELSE 0 END) / COUNT(*),2) AS pct_late_deliveries
FROM runner_orders ro
JOIN customer_orders o ON ro.order_id = o.order_id
WHERE o.order_status = 'completed';
```
**Explanation:** Compute ratio of late dropoffs to all completed deliveries.


---

## Section C — Ingredient Optimisation

### C1. Ingredient usage per month
**Question:** How many units of each ingredient are used each month?
**SQL**
```sql
SELECT pi.ingredient_id, ing.ingredient_name, DATE_FORMAT(o.order_datetime, '%Y-%m') AS year_month,
       SUM(pi.qty_required * oi.quantity) AS total_units_used
FROM pizza_ingredients pi
JOIN ingredients ing ON pi.ingredient_id = ing.ingredient_id
JOIN order_items oi ON pi.pizza_id = oi.pizza_id
JOIN customer_orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY pi.ingredient_id, ing.ingredient_name, year_month
ORDER BY year_month, total_units_used DESC;
```
**Explanation:** Multiply ingredient qty per pizza by pizza quantity ordered and aggregate by month.


### C2. Cost per pizza (ingredient cost)
**Question:** What is the ingredient cost per pizza?
**SQL**
```sql
SELECT p.pizza_id, p.pizza_name,
       ROUND(SUM(pi.qty_required * ing.cost_per_unit),2) AS ingredient_cost
FROM pizza_ingredients pi
JOIN ingredients ing ON pi.ingredient_id = ing.ingredient_id
JOIN pizzas p ON pi.pizza_id = p.pizza_id
GROUP BY p.pizza_id, p.pizza_name
ORDER BY ingredient_cost DESC;
```
**Explanation:** Sum ingredient costs for each pizza to estimate cost of goods sold per pizza.


### C3. Top 5 most expensive ingredients by usage cost this month
**Question:** Which ingredients cost us the most this month based on usage?
**SQL**
```sql
SELECT ing.ingredient_id, ing.ingredient_name,
       ROUND(SUM(pi.qty_required * oi.quantity * ing.cost_per_unit),2) AS total_cost
FROM pizza_ingredients pi
JOIN ingredients ing ON pi.ingredient_id = ing.ingredient_id
JOIN order_items oi ON pi.pizza_id = oi.pizza_id
JOIN customer_orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed' AND DATE_FORMAT(o.order_datetime, '%Y-%m') = DATE_FORMAT(CURDATE(), '%Y-%m')
GROUP BY ing.ingredient_id, ing.ingredient_name
ORDER BY total_cost DESC
LIMIT 5;
```
**Explanation:** Multiply qty * order quantity * cost per unit and aggregate over current month to find cost drivers.


---

## Section D — Pricing and Ratings

### D1. Average rating per pizza
**Question:** Which pizzas have the highest average customer rating?
**SQL**
```sql
SELECT p.pizza_id, p.pizza_name,
       ROUND(AVG(o.rating),2) AS avg_rating,
       COUNT(DISTINCT o.order_id) AS rating_count
FROM customer_orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN pizzas p ON oi.pizza_id = p.pizza_id
WHERE o.rating IS NOT NULL
GROUP BY p.pizza_id, p.pizza_name
ORDER BY avg_rating DESC
LIMIT 10;
```
**Explanation:** Average ratings per pizza; using order_items join to map ratings to pizzas.


### D2. Price sensitivity: average rating before and after price change
**Question:** How did ratings change before vs after a price change?
**SQL**
```sql
WITH before_after AS (
  SELECT o.order_id, oi.pizza_id, o.rating, o.order_datetime, pc.change_date
  FROM customer_orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN price_changes pc ON oi.pizza_id = pc.pizza_id
  WHERE o.order_datetime BETWEEN DATE_SUB(pc.change_date, INTERVAL 90 DAY) AND DATE_ADD(pc.change_date, INTERVAL 90 DAY)
)
SELECT pizza_id, 
       ROUND(AVG(CASE WHEN order_datetime < change_date THEN rating END),2) AS avg_rating_before,
       ROUND(AVG(CASE WHEN order_datetime >= change_date THEN rating END),2) AS avg_rating_after
FROM before_after
GROUP BY pizza_id;
```
**Explanation:** Window around price change to compare ratings pre/post change. Useful for pricing experiments.


---

## Section E — Bonus / Business Questions

### E1. Cancellation rate by reason
**Question:** Why are orders cancelled most often?
**SQL**
```sql
SELECT cancel_reason, COUNT(*) AS cancelled_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_orders),2) AS pct_of_orders
FROM customer_orders
WHERE order_status = 'cancelled'
GROUP BY cancel_reason
ORDER BY cancelled_count DESC;
```
**Explanation:** Counts cancellations by reason to prioritize operational fixes.


### E2. New vs returning customers monthly
**Question:** How many new vs returning customers do we have each month?
**SQL**
```sql
SELECT DATE_FORMAT(order_datetime, '%Y-%m') AS year_month,
       SUM(CASE WHEN first_order = 1 THEN 1 ELSE 0 END) AS new_customers,
       SUM(CASE WHEN first_order = 0 THEN 1 ELSE 0 END) AS returning_customers
FROM (
  SELECT o.*, CASE WHEN o.order_id IN (
        SELECT MIN(order_id) FROM customer_orders GROUP BY customer_id
    ) THEN 1 ELSE 0 END AS first_order
  FROM customer_orders o
) t
GROUP BY year_month
ORDER BY year_month;
```
**Explanation:** Use the first order per customer to tag new vs returning customers per month.


---

