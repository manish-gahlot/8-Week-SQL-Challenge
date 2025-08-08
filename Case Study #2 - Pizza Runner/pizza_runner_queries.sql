/*
Case Study #2 – Pizza Runner (MySQL 8+)
Assumed tables (adapt names if different):
- customer_orders(order_id, customer_id, order_datetime, delivery_datetime, total_price, payment_type, order_status, rating)
- order_items(order_item_id, order_id, pizza_id, quantity, item_price)
- pizzas(pizza_id, pizza_name, size, base_price)
- runners(runner_id, name, start_time, end_time)
- runner_orders(runner_order_id, runner_id, order_id, pickup_time, dropoff_time)
- ingredients(ingredient_id, ingredient_name, cost_per_unit)
- pizza_ingredients(pizza_id, ingredient_id, qty_required)
- customers(customer_id, join_date, city, signup_channel)

Section A - Pizza Metrics

-- A1: Total number of pizzas ordered
SELECT SUM(quantity) AS total_pizzas_ordered FROM order_items;

-- A2: Total revenue (completed orders)
SELECT ROUND(SUM(total_price),2) AS total_revenue
FROM customer_orders
WHERE order_status = 'completed';

-- A3: Average order value (AOV)
SELECT ROUND(AVG(total_price),2) AS avg_order_value
FROM customer_orders
WHERE order_status = 'completed';

-- A4: Top 10 pizzas by quantity sold
SELECT p.pizza_id, p.pizza_name, SUM(oi.quantity) AS qty_sold
FROM order_items oi
JOIN pizzas p ON oi.pizza_id = p.pizza_id
JOIN customer_orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY p.pizza_id, p.pizza_name
ORDER BY qty_sold DESC
LIMIT 10;

-- A5: Monthly orders trend
SELECT DATE_FORMAT(order_datetime, '%Y-%m') AS year_month, COUNT(*) AS orders_count
FROM customer_orders
WHERE order_status = 'completed'
GROUP BY year_month
ORDER BY year_month;

Section B - Runner and Customer Experience

-- B1: Average delivery time (minutes)
SELECT ROUND(AVG(TIMESTAMPDIFF(MINUTE, pickup_time, dropoff_time)),2) AS avg_delivery_minutes
FROM runner_orders ro
JOIN customer_orders o ON ro.order_id = o.order_id
WHERE o.order_status = 'completed';

-- B2: Delivery time distribution (buckets)
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

-- B3: Runner performance: average deliveries per runner in a month
SELECT ro.runner_id, r.name,
       COUNT(DISTINCT ro.order_id) AS deliveries_count,
       ROUND(COUNT(DISTINCT ro.order_id)/COUNT(DISTINCT DATE_FORMAT(ro.pickup_time, '%Y-%m')),2) AS avg_deliveries_per_month
FROM runner_orders ro
JOIN runners r ON ro.runner_id = r.runner_id
JOIN customer_orders o ON ro.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY ro.runner_id, r.name
ORDER BY deliveries_count DESC;

-- B4: Percentage of late deliveries (dropoff_time > promised_time)
-- assume customer_orders has promised_delivery_datetime
SELECT ROUND(100.0 * SUM(CASE WHEN ro.dropoff_time > o.promised_delivery_datetime THEN 1 ELSE 0 END) / COUNT(*),2) AS pct_late_deliveries
FROM runner_orders ro
JOIN customer_orders o ON ro.order_id = o.order_id
WHERE o.order_status = 'completed';

Section C - Ingredient Optimisation

-- C1: Ingredient usage per month
SELECT pi.ingredient_id, ing.ingredient_name, DATE_FORMAT(o.order_datetime, '%Y-%m') AS year_month,
       SUM(pi.qty_required * oi.quantity) AS total_units_used
FROM pizza_ingredients pi
JOIN ingredients ing ON pi.ingredient_id = ing.ingredient_id
JOIN order_items oi ON pi.pizza_id = oi.pizza_id
JOIN customer_orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY pi.ingredient_id, ing.ingredient_name, year_month
ORDER BY year_month, total_units_used DESC;

-- C2: Cost per pizza (ingredient cost)
SELECT p.pizza_id, p.pizza_name,
       ROUND(SUM(pi.qty_required * ing.cost_per_unit),2) AS ingredient_cost
FROM pizza_ingredients pi
JOIN ingredients ing ON pi.ingredient_id = ing.ingredient_id
JOIN pizzas p ON pi.pizza_id = p.pizza_id
GROUP BY p.pizza_id, p.pizza_name
ORDER BY ingredient_cost DESC;

-- C3: Top 5 most expensive ingredients by usage cost this month
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

Section D - Pricing and Ratings

-- D1: Average rating per pizza
SELECT p.pizza_id, p.pizza_name,
       ROUND(AVG(o.rating),2) AS avg_rating,
       COUNT(o.order_id) AS rating_count
FROM customer_orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN pizzas p ON oi.pizza_id = p.pizza_id
WHERE o.rating IS NOT NULL
GROUP BY p.pizza_id, p.pizza_name
ORDER BY avg_rating DESC
LIMIT 10;

-- D2: Price sensitivity: average rating before and after price increase for a pizza
-- assume we have a table price_changes(pizza_id, change_date, old_price, new_price)
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

Section E - Bonus / Business Questions

-- E1: Cancellation rate by reason (if order_status has 'cancelled' with reason column)
SELECT cancel_reason, COUNT(*) AS cancelled_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customer_orders),2) AS pct_of_orders
FROM customer_orders
WHERE order_status = 'cancelled'
GROUP BY cancel_reason
ORDER BY cancelled_count DESC;

-- E2: New vs returning customers monthly
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
