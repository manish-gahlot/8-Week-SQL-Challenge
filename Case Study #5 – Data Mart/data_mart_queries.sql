/*
Case Study #5 – Data Mart (MySQL 8+)
Assumed table:
- weekly_sales(week_date, region, platform, segment, customer_type, transactions, sales)
*/

-- A. Data Cleaning

-- A1: Total records
SELECT COUNT(*) AS total_records
FROM weekly_sales;

-- A2: Distinct regions
SELECT DISTINCT region FROM weekly_sales;

-- A3: Distinct platforms
SELECT DISTINCT platform FROM weekly_sales;

-- B. Sales Performance

-- B1: Total sales by region
SELECT region, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY region
ORDER BY total_sales DESC;

-- B2: Total sales by platform
SELECT platform, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY platform
ORDER BY total_sales DESC;

-- B3: Average weekly sales per region
SELECT region, ROUND(AVG(sales),2) AS avg_weekly_sales
FROM weekly_sales
GROUP BY region
ORDER BY avg_weekly_sales DESC;

-- C. Customer Analysis

-- C1: Total sales by customer type
SELECT customer_type, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY customer_type
ORDER BY total_sales DESC;

-- C2: Average transactions per customer type
SELECT customer_type, ROUND(AVG(transactions),2) AS avg_transactions
FROM weekly_sales
GROUP BY customer_type
ORDER BY avg_transactions DESC;

-- D. Product Segments

-- D1: Total sales by segment
SELECT segment, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY segment
ORDER BY total_sales DESC;

-- D2: Sales percentage share by segment
WITH segment_sales AS (
    SELECT segment, SUM(sales) AS total_sales
    FROM weekly_sales
    GROUP BY segment
)
SELECT segment, total_sales,
       ROUND(total_sales*100/(SELECT SUM(total_sales) FROM segment_sales),2) AS pct_share
FROM segment_sales
ORDER BY pct_share DESC;

-- E. Week-on-Week Changes

-- E1: Sales change per region
WITH weekly_region AS (
    SELECT region, week_date, SUM(sales) AS total_sales
    FROM weekly_sales
    GROUP BY region, week_date
),
diffs AS (
    SELECT region, week_date, total_sales,
           LAG(total_sales) OVER(PARTITION BY region ORDER BY week_date) AS prev_sales
    FROM weekly_region
)
SELECT region, week_date, total_sales, prev_sales,
       total_sales - prev_sales AS change_amount,
       ROUND(100.0 * (total_sales - prev_sales)/prev_sales,2) AS pct_change
FROM diffs
WHERE prev_sales IS NOT NULL
ORDER BY region, week_date;
