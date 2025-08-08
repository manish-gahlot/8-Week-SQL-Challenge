/*
Case Study #4 – Data Bank (MySQL 8+)
Assumed tables:
- customer_nodes(customer_id, region_id, node_id, start_date, end_date)
- customer_transactions(customer_id, txn_date, txn_type, txn_amount)
- regions(region_id, region_name)
*/

-- A. Customer Nodes Exploration

-- A1: How many unique nodes are there?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

-- A2: How many nodes per region?
SELECT r.region_id, r.region_name, COUNT(DISTINCT cn.node_id) AS nodes_count
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;

-- A3: How many customers are allocated to each region?
SELECT r.region_id, r.region_name, COUNT(DISTINCT cn.customer_id) AS customers_count
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;

-- A4: How many days on average are customers active in their node allocation?
SELECT ROUND(AVG(DATEDIFF(end_date, start_date)),0) AS avg_days_active
FROM customer_nodes;

-- B. Customer Transactions

-- B1: Total transactions by type
SELECT txn_type, COUNT(*) AS total_txns
FROM customer_transactions
GROUP BY txn_type;

-- B2: Total transaction value by type
SELECT txn_type, SUM(txn_amount) AS total_value
FROM customer_transactions
GROUP BY txn_type;

-- B3: Average transaction amount by type
SELECT txn_type, ROUND(AVG(txn_amount),2) AS avg_amount
FROM customer_transactions
GROUP BY txn_type;

-- C. Customer Balances

-- C1: Total balance per customer
SELECT customer_id,
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 END) AS balance
FROM customer_transactions
GROUP BY customer_id;

-- C2: Average balance across all customers
WITH balances AS (
    SELECT customer_id,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
                    WHEN txn_type = 'withdrawal' THEN -txn_amount
                    ELSE 0 END) AS balance
    FROM customer_transactions
    GROUP BY customer_id
)
SELECT ROUND(AVG(balance),2) AS avg_balance
FROM balances;

-- D. Regional Analysis

-- D1: Total balance by region
WITH balances AS (
    SELECT customer_id,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
                    WHEN txn_type = 'withdrawal' THEN -txn_amount
                    ELSE 0 END) AS balance
    FROM customer_transactions
    GROUP BY customer_id
)
SELECT r.region_name, SUM(b.balance) AS total_balance
FROM balances b
JOIN customer_nodes cn ON b.customer_id = cn.customer_id
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_name
ORDER BY total_balance DESC;

-- D2: Percentage of total balance per region
WITH balances AS (
    SELECT customer_id,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
                    WHEN txn_type = 'withdrawal' THEN -txn_amount
                    ELSE 0 END) AS balance
    FROM customer_transactions
    GROUP BY customer_id
),
region_balances AS (
    SELECT r.region_name, SUM(b.balance) AS total_balance
    FROM balances b
    JOIN customer_nodes cn ON b.customer_id = cn.customer_id
    JOIN regions r ON cn.region_id = r.region_id
    GROUP BY r.region_name
)
SELECT region_name, total_balance,
       ROUND(total_balance*100/(SELECT SUM(total_balance) FROM region_balances),2) AS pct_share
FROM region_balances
ORDER BY total_balance DESC;
