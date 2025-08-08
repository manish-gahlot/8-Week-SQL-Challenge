/*
Case Study #3 – Foodie-Fi (MySQL 8+)
Assumed tables:
- subscriptions(customer_id, plan_id, start_date)
- plans(plan_id, plan_name, price)
*/

-- A. Customer Journey

-- A1: How many customers are there?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;

-- A2: How many customers signed up for each plan?
SELECT p.plan_id, p.plan_name, COUNT(s.customer_id) AS customers_count
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;

-- A3: How many customers have a trial plan and then paid?
WITH trial_customers AS (
    SELECT customer_id FROM subscriptions WHERE plan_id = 0
),
paid_after_trial AS (
    SELECT DISTINCT s.customer_id
    FROM subscriptions s
    JOIN trial_customers t ON s.customer_id = t.customer_id
    WHERE s.plan_id IN (1,2,3,4)
)
SELECT COUNT(*) AS customers_paid_after_trial FROM paid_after_trial;

-- A4: How many customers have downgraded from pro monthly to basic monthly?
WITH moves AS (
    SELECT customer_id, plan_id,
           LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM subscriptions
)
SELECT COUNT(*) AS downgraded_customers
FROM moves
WHERE plan_id = 2 AND next_plan = 1;

-- B. Customer Churn Analysis

-- B1: Customers who churned
SELECT COUNT(DISTINCT customer_id) AS churned_customers
FROM subscriptions
WHERE plan_id = 4;

-- B2: Churn percentage
SELECT ROUND(100.0 * COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),2) AS churn_percentage
FROM subscriptions
WHERE plan_id = 4;

-- C. Plan Analysis

-- C1: Number and percentage of customers on each plan after 2020
SELECT p.plan_id, p.plan_name,
       COUNT(DISTINCT s.customer_id) AS customers_count,
       ROUND(100.0 * COUNT(DISTINCT s.customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1) AS pct_customers
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE YEAR(s.start_date) > 2020
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id;

-- C2: Customers with annual plan in 2020
SELECT COUNT(DISTINCT customer_id) AS annual_2020_customers
FROM subscriptions
WHERE plan_id = 3 AND YEAR(start_date) = 2020;

-- C3: Average days to upgrade from trial to annual
WITH trial AS (
    SELECT customer_id, start_date AS trial_date FROM subscriptions WHERE plan_id = 0
),
annual AS (
    SELECT customer_id, start_date AS annual_date FROM subscriptions WHERE plan_id = 3
)
SELECT ROUND(AVG(DATEDIFF(a.annual_date, t.trial_date)),0) AS avg_days_to_annual
FROM trial t
JOIN annual a ON t.customer_id = a.customer_id;

-- C4: Distribution of days to upgrade to annual
WITH trial AS (
    SELECT customer_id, start_date AS trial_date FROM subscriptions WHERE plan_id = 0
),
annual AS (
    SELECT customer_id, start_date AS annual_date FROM subscriptions WHERE plan_id = 3
),
diffs AS (
    SELECT DATEDIFF(a.annual_date, t.trial_date) AS days_to_annual
    FROM trial t
    JOIN annual a ON t.customer_id = a.customer_id
),
bins AS (
    SELECT FLOOR(days_to_annual/30) AS bin, days_to_annual FROM diffs
)
SELECT CONCAT(bin*30+1, '-', (bin+1)*30, ' days') AS day_range,
       COUNT(*) AS customers_count
FROM bins
GROUP BY bin
ORDER BY bin;

-- D. Challenge Payment Analysis

-- D1: Average days to upgrade from basic monthly to pro monthly in 2020
WITH basic AS (
    SELECT customer_id, start_date AS basic_date FROM subscriptions WHERE plan_id = 1 AND YEAR(start_date) = 2020
),
pro AS (
    SELECT customer_id, start_date AS pro_date FROM subscriptions WHERE plan_id = 2 AND YEAR(start_date) = 2020
)
SELECT ROUND(AVG(DATEDIFF(p.pro_date, b.basic_date)),0) AS avg_days_basic_to_pro
FROM basic b
JOIN pro p ON b.customer_id = p.customer_id;
