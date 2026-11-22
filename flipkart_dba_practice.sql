/* =====================================================================
   FLIPKART DATASET + DBA PRACTICE QUERIES  (MySQL 8.x / MySQL Workbench)
   How to use:
   1. Open MySQL Workbench -> connect to your local server
   2. File > Open SQL Script > select this file
   3. Run Part 1 and Part 2 first (lightning bolt icon runs the whole script,
      or run section by section with Ctrl+Shift+Enter on a selection)
   4. Then practise Parts 3-11 one query at a time (Ctrl+Enter)
   ===================================================================== */

/* =====================  PART 1: SCHEMA  ===================== */
DROP DATABASE IF EXISTS flipkart_db;
CREATE DATABASE flipkart_db CHARACTER SET utf8mb4;
USE flipkart_db;

CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE sellers (
    seller_id    INT AUTO_INCREMENT PRIMARY KEY,
    seller_name  VARCHAR(80) NOT NULL,
    city         VARCHAR(50),
    rating       DECIMAL(2,1) CHECK (rating BETWEEN 1.0 AND 5.0),
    joined_date  DATE
) ENGINE=InnoDB;

CREATE TABLE custom(
    customer_id     INT AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(80) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    phone           VARCHAR(15),
    city            VARCHAR(50),
    state           VARCHAR(50),
    signup_date     DATE,
    is_plus_member  TINYINT DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id     INT AUTO_INCREMENT PRIMARY KEY,
    product_name   VARCHAR(120) NOT NULL,
    category_id    INT NOT NULL,
    seller_id      INT NOT NULL,
    brand          VARCHAR(50),
    mrp            DECIMAL(10,2) NOT NULL,
    selling_price  DECIMAL(10,2) NOT NULL,
    stock_qty      INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_prod_cat    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    CONSTRAINT fk_prod_seller FOREIGN KEY (seller_id)   REFERENCES sellers(seller_id)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT NOT NULL,
    order_date    DATETIME NOT NULL,
    status        ENUM('Placed','Shipped','Delivered','Cancelled','Returned') NOT NULL,
    payment_mode  ENUM('UPI','Credit Card','Debit Card','COD','Net Banking','EMI') NOT NULL,
    total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    item_id     INT AUTO_INCREMENT PRIMARY KEY,
    order_id    INT NOT NULL,
    product_id  INT NOT NULL,
    quantity    INT NOT NULL,
    unit_price  DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_item_order   FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

CREATE TABLE reviews (
    review_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_id   INT NOT NULL,
    customer_id  INT NOT NULL,
    rating       TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_date  DATE,
    CONSTRAINT fk_rev_prod FOREIGN KEY (product_id)  REFERENCES products(product_id),
    CONSTRAINT fk_rev_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;

CREATE TABLE order_audit (            -- filled by a trigger in Part 7
    audit_id    INT AUTO_INCREMENT PRIMARY KEY,
    order_id    INT,
    old_status  VARCHAR(20),
    new_status  VARCHAR(20),
    changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


/* =====================  PART 2: SAMPLE DATA  ===================== */
INSERT INTO categories (category_name) VALUES
('Mobiles'),('Laptops'),('Electronics'),('Fashion'),('Home & Kitchen'),('Books');

INSERT INTO sellers (seller_name, city, rating, joined_date) VALUES
('RetailNet',           'Bengaluru', 4.6, '2018-03-12'),
('SuperComNet',         'Mumbai',    4.4, '2019-07-01'),
('TechWorld Traders',   'Delhi',     4.1, '2020-01-20'),
('Fashion Hub India',   'Hyderabad', 3.9, '2021-05-15'),
('HomeNeeds Pvt Ltd',   'Pune',      4.3, '2019-11-09'),
('BookBazaar',          'Chennai',   4.7, '2017-08-30');

INSERT INTO customers (full_name, email, phone, city, state, signup_date, is_plus_member) VALUES
('Amit Deshmukh',   'amit.d@example.com',    '9890011111', 'Pune',      'Maharashtra', '2022-01-10', 1),
('Priya Sharma',    'priya.s@example.com',   '9811022222', 'Delhi',     'Delhi',       '2022-03-14', 0),
('Rahul Patil',     'rahul.p@example.com',   '9922033333', 'Dharashiv', 'Maharashtra', '2022-06-21', 0),
('Sneha Kulkarni',  'sneha.k@example.com',   '9763044444', 'Mumbai',    'Maharashtra', '2022-08-02', 1),
('Vikram Reddy',    'vikram.r@example.com',  '9848055555', 'Hyderabad', 'Telangana',   '2023-01-18', 1),
('Anjali Iyer',     'anjali.i@example.com',  '9884066666', 'Chennai',   'Tamil Nadu',  '2023-02-27', 0),
('Rohan Mehta',     'rohan.m@example.com',   '9820077777', 'Mumbai',    'Maharashtra', '2023-04-05', 0),
('Kavita Joshi',    'kavita.j@example.com',  '9890088888', 'Pune',      'Maharashtra', '2023-05-19', 1),
('Arjun Nair',      'arjun.n@example.com',   '9847099999', 'Kochi',     'Kerala',      '2023-07-23', 0),
('Neha Gupta',      'neha.g@example.com',    '9810012345', 'Delhi',     'Delhi',       '2023-09-09', 0),
('Suresh Babu',     'suresh.b@example.com',  '9866023456', 'Bengaluru', 'Karnataka',   '2024-01-12', 1),
('Pooja Singh',     'pooja.s@example.com',   '9831034567', 'Kolkata',   'West Bengal', '2024-02-28', 0),
('Manish Pawar',    'manish.p@example.com',  '9921045678', 'Dharashiv', 'Maharashtra', '2024-04-16', 0),
('Divya Menon',     'divya.m@example.com',   '9880056789', 'Bengaluru', 'Karnataka',   '2024-06-03', 1),
('Karan Malhotra',  'karan.m@example.com',   '9810067890', 'Delhi',     'Delhi',       '2024-08-25', 0);

INSERT INTO products (product_name, category_id, seller_id, brand, mrp, selling_price, stock_qty) VALUES
('Redmi Note 13 5G 128GB',            1, 1, 'Xiaomi',    21999, 17999, 120),
('Samsung Galaxy M35 5G',             1, 2, 'Samsung',   24999, 19999,  85),
('Apple iPhone 15 128GB',             1, 1, 'Apple',     79900, 69999,  30),
('realme Narzo 70 Pro',               1, 3, 'realme',    21999, 16999,   8),
('HP Pavilion 15 Core i5 Laptop',     2, 3, 'HP',        72000, 58990,  25),
('Lenovo IdeaPad Slim 3 Ryzen 5',     2, 2, 'Lenovo',    62000, 44990,  40),
('boAt Rockerz 450 Headphones',       3, 1, 'boAt',       3990,  1299, 500),
('Sony Bravia 43 inch 4K TV',         3, 2, 'Sony',      59900, 31990,  18),
('Mi 20000mAh Power Bank',            3, 3, 'Xiaomi',     2999,  1899, 260),
('Levis 511 Slim Fit Jeans',          4, 4, 'Levis',      3999,  1899, 300),
('Allen Solly Formal Shirt',          4, 4, 'Allen Solly',1999,   899, 410),
('Nike Revolution 7 Running Shoes',   4, 4, 'Nike',       4695,  3299,   6),
('Prestige Induction Cooktop',        5, 5, 'Prestige',   3995,  2199, 150),
('Milton Thermosteel Bottle 1L',      5, 5, 'Milton',     1200,   649, 640),
('Pigeon Mixer Grinder 750W',         5, 5, 'Pigeon',     3495,  1799,  90),
('Atomic Habits (Paperback)',         6, 6, 'Penguin',     799,   399, 700),
('Python Crash Course 3rd Edition',   6, 6, 'No Starch',  2999,  1499, 120),
('Database System Concepts 7th Ed',   6, 6, 'McGraw Hill',1850,  1295,  75),
('Wildcraft 35L Backpack',            4, 4, 'Wildcraft',  2499,  1199, 200),
('Noise ColorFit Pro Smartwatch',     3, 1, 'Noise',      5999,  1999, 330);

/* ---- Bulk-generate 500 orders (random customers, dates, status, payment) ---- */
INSERT INTO orders (customer_id, order_date, status, payment_mode, total_amount)
SELECT 1 + FLOOR(RAND()*15),
       TIMESTAMP('2026-01-01') + INTERVAL FLOOR(RAND()*300) DAY + INTERVAL FLOOR(RAND()*86400) SECOND,
       ELT(1 + FLOOR(RAND()*10),'Delivered','Delivered','Delivered','Delivered','Delivered','Delivered',
                                 'Shipped','Placed','Cancelled','Returned'),
       ELT(1 + FLOOR(RAND()*6),'UPI','UPI','Credit Card','Debit Card','COD','Net Banking'),
       0
FROM (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) a,
     (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
      UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
     (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
      UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c;

/* ---- Two line items per order ---- */
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 1 + MOD(o.order_id + k.k, 3), p.selling_price
FROM orders o
JOIN (SELECT 1 k UNION SELECT 2) k
JOIN products p ON p.product_id = 1 + MOD(o.order_id * (k.k * 4 + 3) + k.k, 20);

SET SQL_SAFE_UPDATES = 0;   -- Workbench blocks joined UPDATEs otherwise
UPDATE orders o
JOIN (SELECT order_id, SUM(quantity * unit_price) AS t FROM order_items GROUP BY order_id) x
  ON x.order_id = o.order_id
SET o.total_amount = x.t;
SET SQL_SAFE_UPDATES = 1;

/* ---- 150 reviews ---- */
INSERT INTO reviews (product_id, customer_id, rating, review_date)
SELECT 1 + MOD(a.d*10 + b.d, 20),
       1 + MOD((a.d*10 + b.d) * 3, 15),
       3 + FLOOR(RAND()*3),
       DATE('2026-01-01') + INTERVAL FLOOR(RAND()*300) DAY
FROM (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6
      UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION SELECT 11 UNION SELECT 12
      UNION SELECT 13 UNION SELECT 14) a,
     (SELECT 0 d UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
      UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b;

-- Sanity check: row counts
SELECT 'customers' tbl, COUNT(*) cnt FROM customers UNION ALL
SELECT 'products', COUNT(*) FROM products UNION ALL
SELECT 'orders', COUNT(*) FROM orders UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews;


/* =====================  PART 3: BASIC QUERIES  ===================== */
-- Q1. All products costing more than Rs 20,000, highest first
SELECT product_name, brand, selling_price FROM products
WHERE selling_price > 20000 ORDER BY selling_price DESC;

-- Q2. Discount % on every product
SELECT product_name, mrp, selling_price,
       ROUND((mrp - selling_price) / mrp * 100, 1) AS discount_pct
FROM products ORDER BY discount_pct DESC;

-- Q3. Customers from Maharashtra who are Flipkart Plus members
SELECT full_name, city FROM customers WHERE state = 'Maharashtra' AND is_plus_member = 1;

-- Q4. Order count by status
SELECT status, COUNT(*) AS orders FROM orders GROUP BY status ORDER BY orders DESC;

-- Q5. Products with low stock (reorder alert)
SELECT product_id, product_name, stock_qty FROM products WHERE stock_qty < 20 ORDER BY stock_qty;


/* =====================  PART 4: JOINS & AGGREGATION  ===================== */
-- Q6. Product with its category and seller
SELECT p.product_name, c.category_name, s.seller_name, p.selling_price
FROM products p
JOIN categories c ON c.category_id = p.category_id
JOIN sellers s    ON s.seller_id   = p.seller_id;

-- Q7. Revenue per category (delivered orders only)
SELECT c.category_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders o     ON o.order_id = oi.order_id AND o.status = 'Delivered'
JOIN products p   ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name ORDER BY revenue DESC;

-- Q8. Top 5 customers by lifetime spend
SELECT c.customer_id, c.full_name, COUNT(DISTINCT o.order_id) AS orders, SUM(o.total_amount) AS spend
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'Delivered'
GROUP BY c.customer_id, c.full_name ORDER BY spend DESC LIMIT 5;

-- Q9. Customers who never placed an order (LEFT JOIN + IS NULL)
SELECT c.customer_id, c.full_name
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Q10. Products never ordered
SELECT p.product_id, p.product_name
FROM products p LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.item_id IS NULL;

-- Q11. Monthly orders and revenue (HAVING filters groups)
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, COUNT(*) AS orders, SUM(total_amount) AS revenue
FROM orders GROUP BY month HAVING COUNT(*) > 30 ORDER BY month;

-- Q12. Cancellation rate by payment mode
SELECT payment_mode,
       COUNT(*) AS total,
       SUM(status = 'Cancelled') AS cancelled,
       ROUND(SUM(status = 'Cancelled') / COUNT(*) * 100, 2) AS cancel_pct
FROM orders GROUP BY payment_mode ORDER BY cancel_pct DESC;

-- Q13. Products priced above their category average (correlated subquery)
SELECT p.product_name, p.selling_price
FROM products p
WHERE p.selling_price > (SELECT AVG(p2.selling_price) FROM products p2 WHERE p2.category_id = p.category_id);

-- Q14. Average rating and review count per product (min 5 reviews)
SELECT p.product_name, ROUND(AVG(r.rating),2) AS avg_rating, COUNT(*) AS reviews
FROM reviews r JOIN products p ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name HAVING COUNT(*) >= 5 ORDER BY avg_rating DESC;


/* =====================  PART 5: WINDOW FUNCTIONS & CTEs  ===================== */
-- Q15. Rank products by revenue inside each category
SELECT * FROM (
  SELECT c.category_name, p.product_name,
         SUM(oi.quantity * oi.unit_price) AS revenue,
         RANK() OVER (PARTITION BY c.category_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS rnk
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  JOIN categories c ON c.category_id = p.category_id
  GROUP BY c.category_name, p.product_name
) t WHERE rnk <= 2;

-- Q16. Running total of monthly revenue
WITH monthly AS (
  SELECT DATE_FORMAT(order_date,'%Y-%m') AS month, SUM(total_amount) AS revenue
  FROM orders WHERE status <> 'Cancelled' GROUP BY month
)
SELECT month, revenue, SUM(revenue) OVER (ORDER BY month) AS running_total FROM monthly;

-- Q17. Month-over-month growth using LAG
WITH monthly AS (
  SELECT DATE_FORMAT(order_date,'%Y-%m') AS month, SUM(total_amount) AS revenue
  FROM orders WHERE status <> 'Cancelled' GROUP BY month
)
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_month,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100, 1) AS growth_pct
FROM monthly;

-- Q18. Days between consecutive orders for each customer
SELECT customer_id, order_id, order_date,
       DATEDIFF(order_date, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS days_since_prev
FROM orders ORDER BY customer_id, order_date LIMIT 30;

-- Q19. Second-highest priced product per category (DENSE_RANK)
SELECT * FROM (
  SELECT category_id, product_name, selling_price,
         DENSE_RANK() OVER (PARTITION BY category_id ORDER BY selling_price DESC) AS dr
  FROM products
) x WHERE dr = 2;

-- Q20. Find duplicate-looking customers by phone prefix + city (data quality pattern)
SELECT city, LEFT(phone, 5) AS prefix, COUNT(*) AS cnt
FROM customers GROUP BY city, LEFT(phone, 5) HAVING COUNT(*) > 1;


/* =====================  PART 6: INDEXING & PERFORMANCE TUNING (core DBA skill)  ===================== */
-- Q21. Check existing indexes
SHOW INDEX FROM orders;

-- Q22. BEFORE index: run EXPLAIN, note type = ALL and rows scanned
EXPLAIN SELECT * FROM orders
WHERE status = 'Delivered' AND order_date BETWEEN '2026-03-01' AND '2026-03-31';

-- Q23. Create a composite index (equality column first, range column second)
CREATE INDEX idx_orders_status_date ON orders (status, order_date);

-- Q24. AFTER index: type should become 'range' and rows should drop
EXPLAIN SELECT * FROM orders
WHERE status = 'Delivered' AND order_date BETWEEN '2026-03-01' AND '2026-03-31';

-- Q25. Non-sargable query (function on column prevents index use) ...
EXPLAIN SELECT * FROM orders WHERE YEAR(order_date) = 2026 AND MONTH(order_date) = 3;
-- ... rewrite as a range so the index can be used
EXPLAIN SELECT * FROM orders WHERE order_date >= '2026-03-01' AND order_date < '2026-04-01';

-- Q26. EXPLAIN ANALYZE gives actual timings (MySQL 8.0.18+)
EXPLAIN ANALYZE
SELECT c.state, SUM(o.total_amount)
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'Delivered' GROUP BY c.state;

-- Q27. Leading wildcard LIKE cannot use a normal index; use FULLTEXT instead
EXPLAIN SELECT * FROM products WHERE product_name LIKE '%Samsung%';
ALTER TABLE products ADD FULLTEXT INDEX ft_product_name (product_name);
SELECT product_name FROM products WHERE MATCH(product_name) AGAINST('Samsung Galaxy');

-- Q28. Covering index: query answered from the index alone ("Using index" in Extra)
CREATE INDEX idx_items_order_prod_qty ON order_items (order_id, product_id, quantity);
EXPLAIN SELECT order_id, SUM(quantity) FROM order_items GROUP BY order_id;

-- Q29. Find unused / redundant indexes (needs performance_schema enabled)
SELECT * FROM sys.schema_unused_indexes WHERE object_schema = 'flipkart_db';
SELECT * FROM sys.schema_redundant_indexes WHERE table_schema = 'flipkart_db';

-- Q30. Drop an index you no longer need
DROP INDEX idx_items_order_prod_qty ON order_items;


/* =====================  PART 7: VIEWS, PROCEDURES, FUNCTIONS, TRIGGERS  ===================== */
-- Q31. View: daily sales summary (hides complexity from analysts)
CREATE OR REPLACE VIEW v_daily_sales AS
SELECT DATE(order_date) AS sale_date, COUNT(*) AS orders, SUM(total_amount) AS revenue
FROM orders WHERE status NOT IN ('Cancelled','Returned') GROUP BY DATE(order_date);

SELECT * FROM v_daily_sales ORDER BY revenue DESC LIMIT 10;

DELIMITER $$

-- Q32. Function: classify customers by spend
CREATE FUNCTION fn_customer_tier(p_customer_id INT) RETURNS VARCHAR(10)
READS SQL DATA
BEGIN
    DECLARE v_spend DECIMAL(12,2);
    SELECT COALESCE(SUM(total_amount),0) INTO v_spend
    FROM orders WHERE customer_id = p_customer_id AND status = 'Delivered';
    RETURN CASE WHEN v_spend >= 500000 THEN 'Platinum'
                WHEN v_spend >= 250000 THEN 'Gold'
                ELSE 'Silver' END;
END$$

-- Q33. Procedure with transaction, row lock and error handling
CREATE PROCEDURE sp_place_order(IN p_customer_id INT, IN p_product_id INT,
                                IN p_qty INT, IN p_mode VARCHAR(20))
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock INT;
    DECLARE v_order_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SELECT selling_price, stock_qty INTO v_price, v_stock
    FROM products WHERE product_id = p_product_id FOR UPDATE;   -- row lock

    IF v_stock < p_qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;

    INSERT INTO orders (customer_id, order_date, status, payment_mode, total_amount)
    VALUES (p_customer_id, NOW(), 'Placed', p_mode, v_price * p_qty);
    SET v_order_id = LAST_INSERT_ID();

    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, p_product_id, p_qty, v_price);

    UPDATE products SET stock_qty = stock_qty - p_qty WHERE product_id = p_product_id;
    COMMIT;
END$$

-- Q34. Trigger: audit every order status change
CREATE TRIGGER trg_order_status_audit
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO order_audit (order_id, old_status, new_status)
        VALUES (OLD.order_id, OLD.status, NEW.status);
    END IF;
END$$

DELIMITER ;

-- Test them
SELECT customer_id, full_name, fn_customer_tier(customer_id) AS tier FROM customers;
CALL sp_place_order(1, 3, 1, 'UPI');          -- succeeds
CALL sp_place_order(1, 4, 9999, 'UPI');       -- fails: Insufficient stock, rolled back
UPDATE orders SET status = 'Shipped' WHERE order_id = 1 AND status = 'Placed';
SELECT * FROM order_audit;


/* =====================  PART 8: TRANSACTIONS & LOCKING (open two Workbench query tabs)  ===================== */
-- Q35. Basic COMMIT / ROLLBACK
START TRANSACTION;
UPDATE products SET stock_qty = stock_qty - 5 WHERE product_id = 7;
SELECT product_id, stock_qty FROM products WHERE product_id = 7;
ROLLBACK;                                      -- stock returns to the original value
SELECT product_id, stock_qty FROM products WHERE product_id = 7;

-- Q36. Create a lock wait: run in TAB 1 (do NOT commit yet)
--   START TRANSACTION;
--   UPDATE products SET stock_qty = stock_qty - 1 WHERE product_id = 1;
-- then in TAB 2 run the same UPDATE: it waits (innodb_lock_wait_timeout = 50s default).
-- Inspect from a THIRD tab:
SELECT * FROM performance_schema.data_lock_waits;
SELECT * FROM sys.innodb_lock_waits\G
SELECT trx_id, trx_state, trx_started, trx_mysql_thread_id FROM information_schema.innodb_trx;
-- Release by running COMMIT in TAB 1, or KILL <thread_id>;

-- Q37. Deadlock demo (TAB 1 and TAB 2, alternate step by step)
--   TAB1: START TRANSACTION; UPDATE products SET stock_qty = stock_qty WHERE product_id = 1;
--   TAB2: START TRANSACTION; UPDATE products SET stock_qty = stock_qty WHERE product_id = 2;
--   TAB1: UPDATE products SET stock_qty = stock_qty WHERE product_id = 2;   -- waits
--   TAB2: UPDATE products SET stock_qty = stock_qty WHERE product_id = 1;   -- ERROR 1213 deadlock
SHOW ENGINE INNODB STATUS\G                    -- see the LATEST DETECTED DEADLOCK section

-- Q38. Isolation level
SELECT @@transaction_isolation;                -- default REPEATABLE-READ
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;


/* =====================  PART 9: USERS, ROLES & SECURITY  ===================== */
-- Q39. Create users with least privilege
CREATE USER 'report_user'@'localhost' IDENTIFIED BY 'Rep0rt#2026';
GRANT SELECT ON flipkart_db.* TO 'report_user'@'localhost';

CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'App#2026Pass';
GRANT SELECT, INSERT, UPDATE ON flipkart_db.orders      TO 'app_user'@'localhost';
GRANT SELECT, INSERT         ON flipkart_db.order_items TO 'app_user'@'localhost';
GRANT SELECT                 ON flipkart_db.products    TO 'app_user'@'localhost';

-- Q40. Roles (MySQL 8)
CREATE ROLE 'analyst_role';
GRANT SELECT ON flipkart_db.* TO 'analyst_role';
CREATE USER 'ravi_analyst'@'localhost' IDENTIFIED BY 'Ravi#2026Pass';
GRANT 'analyst_role' TO 'ravi_analyst'@'localhost';
SET DEFAULT ROLE 'analyst_role' TO 'ravi_analyst'@'localhost';

-- Q41. Audit who has what
SHOW GRANTS FOR 'app_user'@'localhost';
SELECT user, host, account_locked, password_expired FROM mysql.user;

-- Q42. Revoke, expire password, drop
REVOKE INSERT ON flipkart_db.order_items FROM 'app_user'@'localhost';
ALTER USER 'report_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
-- DROP USER 'report_user'@'localhost';

-- Q43. Column masking via view (hide phone and email from analysts)
CREATE OR REPLACE VIEW v_customers_masked AS
SELECT customer_id, full_name,
       CONCAT('XXXXX', RIGHT(phone, 5)) AS phone_masked,
       city, state
FROM customers;


/* =====================  PART 10: MONITORING, SIZING & HEALTH CHECKS  ===================== */
-- Q44. Table sizes (data + index) in MB
SELECT table_name,
       table_rows,
       ROUND(data_length  / 1024 / 1024, 2) AS data_mb,
       ROUND(index_length / 1024 / 1024, 2) AS index_mb
FROM information_schema.tables
WHERE table_schema = 'flipkart_db' ORDER BY data_length + index_length DESC;

-- Q45. Running sessions and long queries
SHOW FULL PROCESSLIST;
SELECT id, user, db, time, state, LEFT(info, 80) AS query
FROM information_schema.processlist WHERE command <> 'Sleep' ORDER BY time DESC;
-- KILL QUERY <id>;

-- Q46. Server status counters worth watching
SHOW GLOBAL STATUS LIKE 'Threads_connected';
SHOW GLOBAL STATUS LIKE 'Threads_running';
SHOW GLOBAL STATUS LIKE 'Slow_queries';
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read%';
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';

-- Q47. Slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
SHOW VARIABLES LIKE 'slow_query_log_file';

-- Q48. Top statements by total time (performance_schema)
SELECT digest_text, count_star, ROUND(sum_timer_wait/1e12, 3) AS total_sec,
       ROUND(avg_timer_wait/1e12, 4) AS avg_sec
FROM performance_schema.events_statements_summary_by_digest
WHERE schema_name = 'flipkart_db' ORDER BY sum_timer_wait DESC LIMIT 10;

-- Q49. Table maintenance
ANALYZE TABLE orders, order_items, products;
CHECK TABLE orders;
OPTIMIZE TABLE orders;

-- Q50. Foreign-key and key info
SELECT constraint_name, table_name, referenced_table_name
FROM information_schema.referential_constraints WHERE constraint_schema = 'flipkart_db';


/* =====================  PART 11: DATA INTEGRITY CHECKS  ===================== */
-- Q51. Orphan check: order_items without a parent order (should return 0 rows)
SELECT oi.item_id FROM order_items oi LEFT JOIN orders o ON o.order_id = oi.order_id WHERE o.order_id IS NULL;

-- Q52. Orders whose total does not match the sum of their items (should return 0 rows)
SELECT o.order_id, o.total_amount, x.item_total
FROM orders o
JOIN (SELECT order_id, SUM(quantity * unit_price) AS item_total FROM order_items GROUP BY order_id) x
  ON x.order_id = o.order_id
WHERE ROUND(o.total_amount, 2) <> ROUND(x.item_total, 2) AND o.order_id <= 500;

-- Q53. Duplicate emails (UNIQUE constraint should prevent; always verify on migrated data)
SELECT email, COUNT(*) FROM customers GROUP BY email HAVING COUNT(*) > 1;

-- Q54. Products where selling price exceeds MRP (bad data)
SELECT product_id, product_name, mrp, selling_price FROM products WHERE selling_price > mrp;

-- Q55. Delete duplicates keeping the lowest id (classic interview question)
-- DELETE c1 FROM customers c1 JOIN customers c2
--   ON c1.email = c2.email AND c1.customer_id > c2.customer_id;


/* =====================  PART 12: BACKUP & RESTORE (run in Command Prompt / terminal, not Workbench)  =====================
   Full logical backup:
     mysqldump -u root -p --single-transaction --routines --triggers --events flipkart_db > flipkart_db_backup.sql

   Backup one table:
     mysqldump -u root -p flipkart_db orders > orders_backup.sql

   Restore:
     mysql -u root -p -e "CREATE DATABASE flipkart_restore"
     mysql -u root -p flipkart_restore < flipkart_db_backup.sql

   Workbench GUI route: Server > Data Export (backup) and Server > Data Import (restore).

   Point-in-time recovery idea: full backup + binary logs
     SHOW BINARY LOGS;
     mysqlbinlog --start-datetime="2026-11-22 10:00:00" --stop-datetime="2026-11-22 12:00:00" binlog.000012 | mysql -u root -p
   ===================================================================== */
