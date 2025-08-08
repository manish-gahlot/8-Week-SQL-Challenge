# Case Study #5 — Data Mart

**Dataset (assumed table)**
- `weekly_sales(week_date, region, platform, segment, customer_type, transactions, sales)`

---

## Section A — Data Cleaning

### A1. Total records
```sql
SELECT COUNT(*) AS total_records
FROM weekly_sales;
```
**Explanation:** Counts all rows in the dataset.

---

### A2. Distinct regions
```sql
SELECT DISTINCT region FROM weekly_sales;
```
**Explanation:** Lists all unique regions.

---

### A3. Distinct platforms
```sql
SELECT DISTINCT platform FROM weekly_sales;
```
**Explanation:** Lists all unique sales platforms.

---

## Section B — Sales Performance

### B1. Total sales by region
```sql
SELECT region, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY region
ORDER BY total_sales DESC;
```
**Explanation:** Sums all sales grouped by region.

---

### B2. Total sales by platform
```sql
SELECT platform, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY platform
ORDER BY total_sales DESC;
```
**Explanation:** Sums all sales grouped by platform.

---

### B3. Average weekly sales per region
```sql
SELECT region, ROUND(AVG(sales),2) AS avg_weekly_sales
FROM weekly_sales
GROUP BY region
ORDER BY avg_weekly_sales DESC;
```
**Explanation:** Averages weekly sales for each region.

---

## Section C — Customer Analysis

### C1. Total sales by customer type
```sql
SELECT customer_type, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY customer_type
ORDER BY total_sales DESC;
```
**Explanation:** Groups sales by customer type.

---

### C2. Average transactions per customer type
```sql
SELECT customer_type, ROUND(AVG(transactions),2) AS avg_transactions
FROM weekly_sales
GROUP BY customer_type
ORDER BY avg_transactions DESC;
```
**Explanation:** Average number of transactions per customer type.

---

## Section D — Product Segments

### D1. Total sales by segment
```sql
SELECT segment, SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY segment
ORDER BY total_sales DESC;
```
**Explanation:** Total sales grouped by product segment.

---

### D2. Sales percentage share by segment
```sql
WITH segment_sales AS (
    SELECT segment, SUM(sales) AS total_sales
    FROM weekly_sales
    GROUP BY segment
)
SELECT segment, total_sales,
       ROUND(total_sales*100/(SELECT SUM(total_sales) FROM segment_sales),2) AS pct_share
FROM segment_sales
ORDER BY pct_share DESC;
```
**Explanation:** Calculates each segment's share of total sales.

---

## Section E — Week-on-Week Changes

### E1. Sales change per region
```sql
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
```
**Explanation:** Compares sales to the previous week's value for each region.

---
