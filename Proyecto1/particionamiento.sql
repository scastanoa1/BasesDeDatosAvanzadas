-- 1
CREATE TABLE ordersp ( 

  order_id      BIGINT NOT NULL, 

  customer_id   BIGINT NOT NULL REFERENCES customer(customer_id), 

  order_date    TIMESTAMPTZ NOT NULL, 

  status        order_status NOT NULL, 

  total_amount  NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0), 

  PRIMARY KEY (order_id, order_date) 

) PARTITION BY RANGE (order_date); 

  

CREATE TABLE ordersp_2021 PARTITION OF ordersp 

FOR VALUES FROM ('2021-01-01') TO ('2022-01-01'); 

  

CREATE TABLE ordersp_2022 PARTITION OF ordersp 

FOR VALUES FROM ('2022-01-01') TO ('2023-01-01'); 

  

CREATE TABLE ordersp_2023 PARTITION OF ordersp 

FOR VALUES FROM ('2023-01-01') TO ('2024-01-01'); 

  

CREATE TABLE ordersp_2024 PARTITION OF ordersp 

FOR VALUES FROM ('2024-01-01') TO ('2025-01-01'); 

  

CREATE TABLE ordersp_2025 PARTITION OF ordersp 

FOR VALUES FROM ('2025-01-01') TO ('2026-01-01'); 

  

CREATE TABLE ordersp_default PARTITION OF ordersp DEFAULT; 

  

CREATE INDEX IF NOT EXISTS idx_ordersp_order_date_inc 

ON ordersp (order_date) INCLUDE (total_amount, customer_id); 

  

CREATE INDEX IF NOT EXISTS idx_ordersp_customer_date_desc 

ON ordersp (customer_id, order_date DESC); 

  

CREATE INDEX IF NOT EXISTS idx_ordersp_customer_id 

ON ordersp (customer_id); 

  

-- Poblar desde orders 

TRUNCATE TABLE ordersp; 

  

INSERT INTO ordersp (order_id, customer_id, order_date, status, total_amount) 

SELECT order_id, customer_id, order_date, status, total_amount 

FROM orders; 

  

ANALYZE ordersp; 

-- 2
CREATE TABLE paymentp ( 

  payment_id     BIGINT NOT NULL, 

  order_id       BIGINT NOT NULL, 

  payment_date   TIMESTAMPTZ NOT NULL, 

  payment_method TEXT NOT NULL, 

  payment_status TEXT NOT NULL, 

  

  PRIMARY KEY (payment_id, payment_status), 

  

  CONSTRAINT paymentp_order_fk 

    FOREIGN KEY (order_id) REFERENCES orders(order_id) 

) 

PARTITION BY LIST (payment_status); 

  

CREATE TABLE paymentp_approved PARTITION OF paymentp FOR VALUES IN ('APPROVED'); 

CREATE TABLE paymentp_declined PARTITION OF paymentp FOR VALUES IN ('DECLINED'); 

CREATE TABLE paymentp_pending  PARTITION OF paymentp FOR VALUES IN ('PENDING'); 

CREATE TABLE paymentp_default  PARTITION OF paymentp DEFAULT; 

  

CREATE INDEX IF NOT EXISTS idx_paymentp_approved_order_id 

  ON paymentp_approved (order_id); 

CREATE INDEX IF NOT EXISTS idx_paymentp_declined_order_id 

  ON paymentp_declined (order_id); 

CREATE INDEX IF NOT EXISTS idx_paymentp_pending_order_id 

  ON paymentp_pending (order_id); 

  

INSERT INTO paymentp (payment_id, order_id, payment_date, payment_method, payment_status) 

SELECT payment_id, order_id, payment_date, payment_method, payment_status 

FROM payment; 

  

ANALYZE paymentp; 

ANALYZE paymentp_approved; 