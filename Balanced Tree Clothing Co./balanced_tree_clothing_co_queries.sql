
/*
Case Study #7 – Balanced Tree Clothing Co. (MySQL 8+)
Assumed tables:
- sales(txn_id, prod_id, qty, price, discount, member, txn_date)
- product_details(prod_id, product_name, category_id, segment_id, style_id, category_name, segment_name, style_name)
- product_prices(prod_id, price)
- members(customer_id, join_date)
*/

-- A. High-Level Sales Analysis

-- A1: Total sales revenue
SELECT SUM(qty * price) AS total_revenue
FROM sales;

-- A2: Total quantity sold
SELECT SUM(qty) AS total_quantity
FROM sales;

-- A3: Total transactions
SELECT COUNT(DISTINCT txn_id) AS total_transactions
FROM sales;

-- A4: Average transaction value
SELECT ROUND(SUM(qty * price) / COUNT(DISTINCT txn_id), 2) AS avg_transaction_value
FROM sales;

-- B. Product Performance

-- B1: Top selling products by quantity
SELECT p.product_name, SUM(s.qty) AS total_sold
FROM sales s
JOIN product_details p ON s.prod_id = p.prod_id
GROUP BY p.product_name
ORDER BY total_sold DESC;

-- B2: Top revenue-generating products
SELECT p.product_name, SUM(s.qty * s.price) AS total_revenue
FROM sales s
JOIN product_details p ON s.prod_id = p.prod_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- B3: Category-wise sales revenue
SELECT p.category_name, SUM(s.qty * s.price) AS category_revenue
FROM sales s
JOIN product_details p ON s.prod_id = p.prod_id
GROUP BY p.category_name
ORDER BY category_revenue DESC;

-- B4: Segment-wise quantity sold
SELECT p.segment_name, SUM(s.qty) AS total_qty
FROM sales s
JOIN product_details p ON s.prod_id = p.prod_id
GROUP BY p.segment_name
ORDER BY total_qty DESC;

-- C. Discount Impact

-- C1: Average discount by category
SELECT p.category_name, ROUND(AVG(s.discount), 2) AS avg_discount
FROM sales s
JOIN product_details p ON s.prod_id = p.prod_id
GROUP BY p.category_name;

-- C2: Revenue impact of discounts
SELECT 
    SUM(qty * price) AS revenue_with_discount,
    SUM(qty * (price / (1 - discount))) AS revenue_without_discount,
    ROUND(SUM(qty * price) - SUM(qty * (price / (1 - discount))), 2) AS discount_impact
FROM sales;

-- D. Member vs Non-Member Analysis

-- D1: Revenue by membership status
SELECT member, SUM(qty * price) AS total_revenue
FROM sales
GROUP BY member;

-- D2: Average transaction value by membership status
SELECT member, ROUND(SUM(qty * price) / COUNT(DISTINCT txn_id), 2) AS avg_transaction_value
FROM sales
GROUP BY member;

-- D3: Top products for members vs non-members
SELECT member, p.product_name, SUM(qty) AS total_sold
FROM sales s
JOIN product_details p ON s.prod_id = p.prod_id
GROUP BY member, p.product_name
ORDER BY member, total_sold DESC;

-- E. Time-Based Analysis

-- E1: Monthly revenue trend
SELECT DATE_FORMAT(txn_date, '%Y-%m') AS month, SUM(qty * price) AS monthly_revenue
FROM sales
GROUP BY month
ORDER BY month;

-- E2: Day-of-week revenue pattern
SELECT DAYNAME(txn_date) AS day_of_week, SUM(qty * price) AS revenue
FROM sales
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- E3: Hourly sales trend
SELECT HOUR(txn_date) AS hour_of_day, SUM(qty * price) AS revenue
FROM sales
GROUP BY hour_of_day
ORDER BY hour_of_day;
