# Case Study #1 — Danny's Diner

**Dataset (assumed tables)**  
- `orders(order_id, customer_id, order_datetime, total_amount, payment_type, order_status)`  
- `order_items(order_item_id, order_id, menu_item_id, quantity, item_price)`  
- `menu(menu_item_id, item_name, category, cost_price, list_price)`  
- `customers(customer_id, join_date, city, email)`  
- `staff(staff_id, name, role)`  
- `shifts(shift_id, staff_id, shift_date, start_time, end_time)`

> If your dataset uses different column names, update the SQL accordingly.

---

## Q1 — What is the total revenue (all time)?
**Problem:** Calculate total revenue from completed orders.  
**SQL**
```sql
SELECT ROUND(SUM(total_amount), 2) AS total_revenue
FROM orders
WHERE order_status = 'completed';

## Q2 — How many days has each customer visited the restaurant?
**SQL**
```sql
SSELECT customer_id,
       COUNT(DISTINCT order_date) AS visit_days
FROM sales
GROUP BY customer_id;
