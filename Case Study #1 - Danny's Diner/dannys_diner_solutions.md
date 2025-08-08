# Case Study #1 — Danny's Diner

**Dataset (assumed tables)**  
- `sales(customer_id, order_date, product_id)`  
- `menu(product_id, product_name, price)`  
- `members(customer_id, join_date)`

> These tables match the schema from the official 8 Week SQL Challenge for Danny's Diner. If your column or table names differ, adjust accordingly.

---

## Q1 — What is the total amount each customer spent at the restaurant?
**SQL**
```sql
SELECT s.customer_id,
       SUM(m.price) AS total_spent
FROM sales s
JOIN menu m 
  ON s.product_id = m.product_id
GROUP BY s.customer_id;
```
**Explanation:**  
We join `sales` with `menu` to get the price of each product purchased. Then we sum the prices for each `customer_id`.  


---

## Q2 — How many days has each customer visited the restaurant?
**SQL**
```sql
SELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_days
FROM sales
GROUP BY customer_id;
```
**Explanation:**  
We count distinct `order_date` per customer to find how many separate days they visited.  


---

## Q3 — What was the first item from the menu purchased by each customer?
**SQL**
```sql
WITH first_purchase AS (
    SELECT s.customer_id,
           s.product_id,
           m.product_name,
           s.order_date,
           RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales s
    JOIN menu m 
      ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM first_purchase
WHERE rnk = 1;
```
**Explanation:**  
We use `RANK()` to order each customer’s purchases by date, then select the first one(s). If a customer bought multiple items on their first day, they will all be returned.  


---

## Q4 — What is the most purchased item on the menu and how many times was it purchased by all customers?
**SQL**
```sql
SELECT m.product_name,
       COUNT(*) AS total_orders
FROM sales s
JOIN menu m 
  ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_orders DESC
LIMIT 1;
```
**Explanation:**  
We group all sales by product and count the total orders, ordering in descending order to find the top-selling item.  


---

## Q5 — Which item was the most popular for each customer?
**SQL**
```sql
WITH customer_item_rank AS (
    SELECT s.customer_id,
           m.product_name,
           COUNT(*) AS order_count,
           RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rnk
    FROM sales s
    JOIN menu m 
      ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, order_count
FROM customer_item_rank
WHERE rnk = 1;
```
**Explanation:**  
For each customer, we count orders of each product and rank them from most to least ordered, then filter to only the top-ranked items.  


---

## Q6 — Which item was purchased first by the customer after they became a member?
**SQL**
```sql
WITH joined_data AS (
    SELECT s.customer_id,
           s.product_id,
           m.product_name,
           s.order_date,
           mem.join_date
    FROM sales s
    JOIN menu m 
      ON s.product_id = m.product_id
    JOIN members mem 
      ON s.customer_id = mem.customer_id
    WHERE s.order_date >= mem.join_date
),
ranked AS (
    SELECT *,
           RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rnk
    FROM joined_data
)
SELECT customer_id, product_name, order_date
FROM ranked
WHERE rnk = 1;
```
**Explanation:**  
We filter sales to only those made on or after the `join_date`, rank them by date for each customer, and return the first purchase.  


---

## Q7 — Which item was purchased just before the customer became a member?
**SQL**
```sql
WITH pre_member_sales AS (
    SELECT s.customer_id,
           s.product_id,
           m.product_name,
           s.order_date,
           mem.join_date
    FROM sales s
    JOIN menu m 
      ON s.product_id = m.product_id
    JOIN members mem 
      ON s.customer_id = mem.customer_id
    WHERE s.order_date < mem.join_date
),
ranked AS (
    SELECT *,
           RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rnk
    FROM pre_member_sales
)
SELECT customer_id, product_name, order_date
FROM ranked
WHERE rnk = 1;
```
**Explanation:**  
We filter sales to only those before the membership date, rank them in reverse order by date, and return the most recent purchase before joining.  


---

## Q8 — What is the total items and amount spent for each member before they became a member?
**SQL**
```sql
SELECT s.customer_id,
       COUNT(s.product_id) AS total_items,
       SUM(m.price) AS total_amount
FROM sales s
JOIN menu m 
  ON s.product_id = m.product_id
JOIN members mem 
  ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;
```
**Explanation:**  
We filter sales to pre-membership dates and aggregate item counts and total spend for each customer.  


---

## Q9 — If each $1 spent equates to 10 points, and sushi has a 2x points multiplier, how many points would each customer have?
**SQL**
```sql
SELECT s.customer_id,
       SUM(
         CASE 
           WHEN m.product_name = 'sushi' THEN m.price * 20
           ELSE m.price * 10
         END
       ) AS total_points
FROM sales s
JOIN menu m 
  ON s.product_id = m.product_id
GROUP BY s.customer_id;
```
**Explanation:**  
We multiply the price by 10 points per dollar, except sushi which earns double (20 points per dollar). The sum is grouped by customer.  


---

## Q10 — In the first week after a customer joins (including join date), how many points do they earn, and which item generates the most points for them?
**SQL**
```sql
WITH first_week_sales AS (
    SELECT s.customer_id,
           m.product_name,
           m.price,
           mem.join_date,
           s.order_date
    FROM sales s
    JOIN menu m 
      ON s.product_id = m.product_id
    JOIN members mem 
      ON s.customer_id = mem.customer_id
    WHERE s.order_date BETWEEN mem.join_date AND DATE_ADD(mem.join_date, INTERVAL 6 DAY)
)
SELECT customer_id,
       product_name,
       SUM(
         CASE 
           WHEN product_name = 'sushi' THEN price * 20
           ELSE price * 10
         END
       ) AS points
FROM first_week_sales
GROUP BY customer_id, product_name
ORDER BY customer_id, points DESC;
```
**Explanation:**  
We filter sales to within the first 7 days (join date + 6 days), apply the points logic, then sum points per product for each customer to see the top point-generating item(s).  


---


