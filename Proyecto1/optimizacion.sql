-- Q1
DROP MATERIALIZED VIEW IF EXISTS mv_q1_top_ciudades_ventas;

CREATE MATERIALIZED VIEW mv_q1_top_ciudades_ventas AS
SELECT
  c.city,
  SUM(o.total_amount) AS total_sales
FROM ordersp o
JOIN customer c ON c.customer_id = o.customer_id
WHERE o.order_date >= TIMESTAMPTZ '2023-01-01'
  AND o.order_date <  TIMESTAMPTZ '2024-01-01'
GROUP BY c.city;

CREATE INDEX IF NOT EXISTS mv_q1_top_ciudades_ventas_total_sales_desc_idx
ON mv_q1_top_ciudades_ventas (total_sales DESC);

SELECT city, total_sales
FROM mv_q1_top_ciudades_ventas
ORDER BY total_sales DESC
LIMIT 10;

--Q2
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.name, x.total_sold
FROM(
    SELECT product_id, SUM(quantity) AS total_sold
    FROM order_item
    GROUP BY product_id
) x
JOIN product p ON p.product_id = x.product_id
ORDER BY x.total_sold DESC
LIMIT 10;

--Q5 
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM orders
WHERE order_date >= TIMESTAMPTZ '2023-11-15'
  AND order_date <  TIMESTAMPTZ '2023-11-16';

-- Q6
CREATE MATERIALIZED VIEW mv_q6_orders_status_approved AS
SELECT o.status, COUNT(*) AS total
FROM orders o
JOIN paymentp p ON p.order_id = o.order_id
WHERE p.payment_status = 'APPROVED'
GROUP BY o.status;

SELECT status, total
FROM mv_q6_orders_status_approved
ORDER BY total DESC
LIMIT 5;