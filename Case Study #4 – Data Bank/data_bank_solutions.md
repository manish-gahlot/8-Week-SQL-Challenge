# Case Study #4 — Data Bank

**Dataset (assumed tables)**
- `customer_nodes(customer_id, region_id, node_id, start_date, end_date)`
- `customer_transactions(customer_id, txn_date, txn_type, txn_amount)`
- `regions(region_id, region_name)`

---

## Section A — Customer Nodes Exploration

### A1. Unique nodes count
```sql
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;
```
**Explanation:** Counts the distinct nodes allocated to customers.

---

### A2. Nodes per region
```sql
SELECT r.region_id, r.region_name, COUNT(DISTINCT cn.node_id) AS nodes_count
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;
```
**Explanation:** Groups nodes by region and counts distinct node IDs.

---

### A3. Customers per region
```sql
SELECT r.region_id, r.region_name, COUNT(DISTINCT cn.customer_id) AS customers_count
FROM customer_nodes cn
JOIN regions r ON cn.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;
```
**Explanation:** Counts how many customers belong to each region.

---

### A4. Average active days in node allocation
```sql
SELECT ROUND(AVG(DATEDIFF(end_date, start_date)),0) AS avg_days_active
FROM customer_nodes;
```
**Explanation:** Average number of days between allocation start and end.

---

## Section B — Customer Transactions

### B1. Transactions by type
```sql
SELECT txn_type, COUNT(*) AS total_txns
FROM customer_transactions
GROUP BY txn_type;
```
**Explanation:** Counts how many transactions occur for each type.

---

### B2. Transaction value by type
```sql
SELECT txn_type, SUM(txn_amount) AS total_value
FROM customer_transactions
GROUP BY txn_type;
```
**Explanation:** Sums transaction amounts by type.

---

### B3. Average transaction amount by type
```sql
SELECT txn_type, ROUND(AVG(txn_amount),2) AS avg_amount
FROM customer_transactions
GROUP BY txn_type;
```
**Explanation:** Calculates average value per transaction type.

---

## Section C — Customer Balances

### C1. Total balance per customer
```sql
SELECT customer_id,
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 END) AS balance
FROM customer_transactions
GROUP BY customer_id;
```
**Explanation:** Adds deposits and subtracts withdrawals for each customer.

---

### C2. Average balance across customers
```sql
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
```
**Explanation:** Calculates average of all customers' balances.

---

## Section D — Regional Analysis

### D1. Total balance by region
```sql
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
```
**Explanation:** Sums balances for customers grouped by their region.

---

### D2. Percentage of total balance per region
```sql
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
```
**Explanation:** Calculates each region's share of the total customer balance.

---
