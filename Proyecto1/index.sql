-- Q1
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date)
INCLUDE (customer_id, total_amount);

-- Q2
CREATE INDEX IF NOT EXISTS idx_order_item_product_id ON order_item(product_id);

-- Q3
CREATE INDEX IF NOT EXISTS idx_orders_customer_date_desc 
ON orders(customer_id, order_date DESC);

-- Q4
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_product_name_trgm 
ON product USING gin (name gin_trgm_ops);

-- Q6
CREATE INDEX IF NOT EXISTS idx_payment_order_id ON payment(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_approved_order ON payment(order_id) WHERE payment_status = 'APPROVED';

-- Q7
CREATE INDEX IF NOT EXISTS idx_orders_order_date_order_id
ON orders (order_date, order_id);
CREATE INDEX IF NOT EXISTS idx_order_item_order_id_inc
ON order_item (order_id)
INCLUDE (product_id, quantity, unit_price);

-- Q8
CREATE INDEX IF NOT EXISTS idx_orders_odate_cust_inc
ON orders (order_date, customer_id)
INCLUDE (total_amount);