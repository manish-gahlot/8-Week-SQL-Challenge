/*
Case Study #6 – Clique Bait (MySQL 8+)
Assumed tables:
- events(customer_id, page_id, event_type, event_time)
- event_identifier(event_type, event_name)
- page_hierarchy(page_id, page_name, product_category, product_id)
*/

-- A. Event Analysis

-- A1: Count distinct customers
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM events;

-- A2: Count events by type
SELECT event_type, COUNT(*) AS total_events
FROM events
GROUP BY event_type;

-- A3: Count events by event name
SELECT ei.event_name, COUNT(*) AS total_events
FROM events e
JOIN event_identifier ei ON e.event_type = ei.event_type
GROUP BY ei.event_name
ORDER BY total_events DESC;

-- B. Funnel Analysis

-- B1: Page views per product category
SELECT ph.product_category, COUNT(*) AS total_pageviews
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = 1
GROUP BY ph.product_category
ORDER BY total_pageviews DESC;

-- B2: Add-to-cart events per product category
SELECT ph.product_category, COUNT(*) AS total_add_to_cart
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = 2
GROUP BY ph.product_category
ORDER BY total_add_to_cart DESC;

-- B3: Purchase events per product category
SELECT ph.product_category, COUNT(*) AS total_purchases
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = 3
GROUP BY ph.product_category
ORDER BY total_purchases DESC;

-- C. Conversion Rates

-- C1: Conversion rate from page view to add-to-cart
WITH views AS (
    SELECT ph.product_category, COUNT(*) AS views_count
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE e.event_type = 1
    GROUP BY ph.product_category
),
carts AS (
    SELECT ph.product_category, COUNT(*) AS carts_count
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE e.event_type = 2
    GROUP BY ph.product_category
)
SELECT v.product_category,
       ROUND(carts_count*100.0/views_count,2) AS view_to_cart_pct
FROM views v
JOIN carts c ON v.product_category = c.product_category;

-- C2: Conversion rate from add-to-cart to purchase
WITH carts AS (
    SELECT ph.product_category, COUNT(*) AS carts_count
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE e.event_type = 2
    GROUP BY ph.product_category
),
purchases AS (
    SELECT ph.product_category, COUNT(*) AS purchases_count
    FROM events e
    JOIN page_hierarchy ph ON e.page_id = ph.page_id
    WHERE e.event_type = 3
    GROUP BY ph.product_category
)
SELECT c.product_category,
       ROUND(purchases_count*100.0/carts_count,2) AS cart_to_purchase_pct
FROM carts c
JOIN purchases p ON c.product_category = p.product_category;

-- D. Product Analysis

-- D1: Most viewed products
SELECT ph.product_id, ph.page_name, COUNT(*) AS views_count
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = 1
GROUP BY ph.product_id, ph.page_name
ORDER BY views_count DESC;

-- D2: Top purchased products
SELECT ph.product_id, ph.page_name, COUNT(*) AS purchase_count
FROM events e
JOIN page_hierarchy ph ON e.page_id = ph.page_id
WHERE e.event_type = 3
GROUP BY ph.product_id, ph.page_name
ORDER BY purchase_count DESC;
