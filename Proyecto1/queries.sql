-- Q1: Ventas por ciudad en un año (sin índices en orders.order_date ni orders.customer_id)
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.city, SUM(o.total_amount) AS total_sales
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= TIMESTAMPTZ '2023-01-01'
  AND o.order_date <  TIMESTAMPTZ '2024-01-01'
GROUP BY c.city
ORDER BY total_sales DESC;

-- Q2: Top productos vendidos (agregación masiva)
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM order_item oi
JOIN product p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_sold DESC
LIMIT 10;

-- Q3: Dashboard: últimas órdenes de un cliente (filtro + sort)
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE customer_id = 12345
ORDER BY order_date DESC
LIMIT 20;

-- Q4: Degradación típica: LIKE con comodín inicial (no sargable)
-- (Incluso con índice normal, '%texto' suele forzar scan)
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM product
WHERE name ILIKE '%42%'
LIMIT 50;

-- Q5: Anti-pattern: función sobre columna en WHERE (rompe uso directo de índice)
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM orders
WHERE date_trunc('day', order_date) = TIMESTAMPTZ '2023-11-15';

-- Q6: Join + filtro por status (sin índices)
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.status, count(*) AS n
FROM orders o
JOIN payment p ON p.order_id = o.order_id
WHERE p.payment_status = 'APPROVED'
GROUP BY o.status
ORDER BY n DESC;

-- Q8 (Top 50 productos por ingresos en un mes)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
  p.category, 
  p.product_id, 
  p.name, 
  SUM(oi.quantity * oi.unit_price) AS revenue, 
  SUM(oi.quantity) AS units_sold 
FROM order_item oi 
JOIN orders o   ON o.order_id = oi.order_id 
JOIN product p  ON p.product_id = oi.product_id 
WHERE o.order_date >= '2023-01-01'::timestamptz 
  AND o.order_date <  '2023-02-01'::timestamptz 
GROUP BY p.category, p.product_id, p.name 
ORDER BY revenue DESC 
LIMIT 50; 

-- Q8 (Top Clientes con más gasto)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
  c.customer_id, 
  c.city, 
  SUM(o.total_amount) AS total_spent, 
  COUNT(*) AS orders_count 
FROM orders o 
JOIN customer c ON c.customer_id = o.customer_id 
WHERE o.order_date >= '2023-01-01'::timestamptz 
  AND o.order_date <  '2024-01-01'::timestamptz 
GROUP BY c.customer_id, c.city 
ORDER BY total_spent DESC 
LIMIT 50; 