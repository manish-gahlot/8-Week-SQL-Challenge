/*
Case Study #1 – Danny's Diner
MySQL queries (MySQL 8+). Replace table/column names if your dataset differs.
Common tables (assumed):
- orders(order_id, customer_id, order_datetime, total_amount, payment_type, order_status)
- order_items(order_item_id, order_id, menu_item_id, quantity, item_price)
- menu(menu_item_id, item_name, category, cost_price, list_price)
- customers(customer_id, join_date, city, email)
- staff(staff_id, name, role)
- shifts(shift_id, staff_id, shift_date, start_time, end_time)

Adjust table names and column names as needed.
*/

/* 1. Total revenue (all time) */
SELECT ROUND(SUM(total_amount), 2) AS total_revenue
FROM orders
WHERE order_status = 'completed';

/* 2. Total number of completed orders */
SELECT COUNT(*) AS total_completed_orders
FROM orders
WHERE order_status = 'completed';

/* 3. Average order value (AOV) */
SELECT ROUND(AVG(total_amount), 2) AS avg_order_value
FROM orders
WHERE order_status = 'completed';

/* 4. Top 10 best-selling menu items by quantity */
SELECT m.menu_item_id, m.item_name, SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN menu m ON oi.menu_item_id = m.menu_item_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY m.menu_item_id, m.item_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

/* 5. Top 10 menu items by revenue (quantity * item_price) */
SELECT m.menu_item_id, m.item_name, 
       ROUND(SUM(oi.quantity * oi.item_price),2) AS revenue_generated
FROM order_items oi
JOIN menu m ON oi.menu_item_id = m.menu_item_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY m.menu_item_id, m.item_name
ORDER BY revenue_generated DESC
LIMIT 10;

/* 6. Monthly revenue trend (year-month) */
SELECT DATE_FORMAT(o.order_datetime, '%Y-%m') AS year_month,
       ROUND(SUM(o.total_amount),2) AS monthly_revenue
FROM orders o
WHERE o.order_status = 'completed'
GROUP BY year_month
ORDER BY year_month;

/* 7. Repeat customers: customers with >1 completed order */
SELECT customer_id, COUNT(*) AS completed_orders
FROM orders
WHERE order_status = 'completed'
GROUP BY customer_id
HAVING completed_orders > 1
ORDER BY completed_orders DESC;

/* 8. Top 10 customers by lifetime revenue */
SELECT o.customer_id,
       ROUND(SUM(o.total_amount),2) AS lifetime_revenue,
       COUNT(DISTINCT o.order_id) AS orders_count
FROM orders o
WHERE o.order_status = 'completed'
GROUP BY o.customer_id
ORDER BY lifetime_revenue DESC
LIMIT 10;

/* 9. Menu item gross margin (approx) = (list_price - cost_price) * qty sold */
SELECT m.menu_item_id, m.item_name,
       m.list_price, m.cost_price,
       SUM(oi.quantity) AS qty_sold,
       ROUND(SUM(oi.quantity) * (m.list_price - m.cost_price),2) AS approx_gross_profit
FROM order_items oi
JOIN menu m ON oi.menu_item_id = m.menu_item_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'completed'
GROUP BY m.menu_item_id, m.item_name, m.list_price, m.cost_price
ORDER BY approx_gross_profit DESC
LIMIT 15;

/* 10. Peak hour (hour of day with highest revenue) */
SELECT HOUR(order_datetime) AS hour_of_day,
       ROUND(SUM(total_amount),2) AS revenue
FROM orders
WHERE order_status = 'completed'
GROUP BY hour_of_day
ORDER BY revenue DESC
LIMIT 1;

/* 11. Order counts by day of week (to identify busiest weekday) */
SELECT DAYNAME(order_datetime) AS day_of_week,
       COUNT(*) AS orders_count,
       ROUND(SUM(total_amount),2) AS revenue
FROM orders
WHERE order_status = 'completed'
GROUP BY day_of_week
ORDER BY FIELD(day_of_week,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

/* 12. Churn / retention proxy: customers who ordered in period A but not in period B
   Example: customers who ordered in 2020 but not in 2021 */
WITH customers_2020 AS (
  SELECT DISTINCT customer_id
  FROM orders
  WHERE order_status = 'completed' AND YEAR(order_datetime) = 2020
),
customers_2021 AS (
  SELECT DISTINCT customer_id
  FROM orders
  WHERE order_status = 'completed' AND YEAR(order_datetime) = 2021
)
SELECT COUNT(*) AS customers_lost
FROM customers_2020 c
LEFT JOIN customers_2021 c2 ON c.customer_id = c2.customer_id
WHERE c2.customer_id IS NULL;

/* 13. Average items per order */
SELECT ROUND(AVG(items_per_order),2) AS avg_items_per_order FROM (
  SELECT oi.order_id, SUM(oi.quantity) AS items_per_order
  FROM order_items oi
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.order_status = 'completed'
  GROUP BY oi.order_id
) x;

/* 14. % of orders paid by each payment type */
SELECT payment_type,
       COUNT(*) AS orders_count,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders WHERE order_status = 'completed'),2) AS pct_of_orders
FROM orders
WHERE order_status = 'completed'
GROUP BY payment_type
ORDER BY orders_count DESC;

