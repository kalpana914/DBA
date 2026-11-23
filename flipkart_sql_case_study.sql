/* =====================================================================
   FLIPKART E-COMMERCE CASE STUDY  -  SQL FROM BASIC TO ADVANCED
   Tested for: MySQL Workbench (MySQL 8.0+)
   How to run: File > Open SQL Script > run the whole script once (lightning
   icon) to build data. Then select ONE query at a time and press
   Ctrl+Shift+Enter to run only that query.
   ===================================================================== */

/* ---------------------------------------------------------------------
   PART 0 : SETUP  (database, tables, sample data)
   --------------------------------------------------------------------- */
DROP DATABASE IF EXISTS flipkart_db;
CREATE DATABASE flipkart_db;
USE flipkart_db;

CREATE TABLE customers (
    customer_id  INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(60)  NOT NULL,
    email        VARCHAR(80)  UNIQUE,
    city         VARCHAR(40),
    state        VARCHAR(40),
    signup_date  DATE,
    is_plus      TINYINT(1) DEFAULT 0          -- Flipkart Plus member? 1/0
);

CREATE TABLE categories (
    category_id   INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(40) NOT NULL
);

CREATE TABLE products (
    product_id   INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(80) NOT NULL,
    category_id  INT,
    brand        VARCHAR(40),
    price        DECIMAL(10,2) NOT NULL,
    stock_qty    INT DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

CREATE TABLE orders (
    order_id     INT PRIMARY KEY AUTO_INCREMENT,
    customer_id  INT,
    order_date   DATE,
    order_status VARCHAR(20),                  -- Placed/Shipped/Delivered/Cancelled/Returned
    total_amount DECIMAL(12,2) DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id      INT PRIMARY KEY AUTO_INCREMENT,
    order_id     INT,
    product_id   INT,
    quantity     INT,
    unit_price   DECIMAL(10,2),
    discount_pct DECIMAL(5,2) DEFAULT 0,
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id     INT PRIMARY KEY AUTO_INCREMENT,
    order_id       INT,
    payment_mode   VARCHAR(20),                -- UPI/Credit Card/Debit Card/COD/EMI/Net Banking
    payment_status VARCHAR(20),                -- Success/Pending/Refunded
    paid_at        DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE reviews (
    review_id   INT PRIMARY KEY AUTO_INCREMENT,
    product_id  INT,
    customer_id INT,
    rating      INT,
    review_date DATE,
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO customers (name,email,city,state,signup_date,is_plus) VALUES
('Aarav Sharma','aarav@mail.com','Pune','Maharashtra','2024-01-15',1),
('Priya Nair','priya@mail.com','Bengaluru','Karnataka','2024-03-10',0),
('Rohan Mehta','rohan@mail.com','Mumbai','Maharashtra','2024-05-22',1),
('Sneha Reddy','sneha@mail.com','Hyderabad','Telangana','2024-07-01',0),
('Vikram Singh','vikram@mail.com','Delhi','Delhi','2024-09-18',0),
('Ananya Iyer','ananya@mail.com','Chennai','Tamil Nadu','2025-01-05',1),
('Karan Patel','karan@mail.com','Ahmedabad','Gujarat','2025-02-14',0),
('Meera Joshi','meera@mail.com','Pune','Maharashtra','2025-06-30',0);

INSERT INTO categories (category_name) VALUES
('Electronics'),('Fashion'),('Home & Kitchen'),('Books'),('Grocery');

INSERT INTO products (product_name,category_id,brand,price,stock_qty) VALUES
('Redmi Note 13 5G',1,'Xiaomi',17999,120),
('boAt Rockerz 450',1,'boAt',1499,300),
('HP 15s Laptop',1,'HP',48990,40),
('Slim Fit Jeans',2,'Levis',2299,150),
('Running Shoes',2,'Puma',3499,90),
('Cotton T-Shirt',2,'Roadster',599,400),
('Induction Cooktop',3,'Prestige',2799,70),
('Steel Water Bottle',3,'Milton',699,250),
('Atomic Habits',4,'Penguin',499,500),
('Rich Dad Poor Dad',4,'Manjul',349,450),
('Atta 10kg',5,'Aashirvaad',520,600),
('Sunflower Oil 5L',5,'Fortune',780,5);

INSERT INTO orders (customer_id,order_date,order_status) VALUES
(1,'2026-09-25','Delivered'),  -- 1
(2,'2026-10-05','Delivered'),  -- 2
(3,'2026-10-12','Delivered'),  -- 3
(1,'2026-10-20','Delivered'),  -- 4
(4,'2026-11-01','Cancelled'),  -- 5
(5,'2026-11-03','Delivered'),  -- 6
(6,'2026-11-05','Shipped'),    -- 7
(3,'2026-11-08','Delivered'),  -- 8
(2,'2026-11-10','Returned'),   -- 9
(7,'2026-11-12','Delivered'),  -- 10
(1,'2026-11-18','Placed'),     -- 11
(6,'2026-11-20','Delivered'),  -- 12
(5,'2026-11-22','Shipped'),    -- 13
(4,'2026-09-28','Delivered'),  -- 14
(7,'2026-09-30','Delivered');  -- 15

INSERT INTO order_items (order_id,product_id,quantity,unit_price,discount_pct) VALUES
(1,1,1,17999,10),(1,2,1,1499,0),
(2,4,1,2299,20),(2,6,2,599,0),
(3,3,1,48990,5),
(4,9,2,499,0),(4,10,1,349,0),(4,8,1,699,0),
(5,5,1,3499,15),
(6,7,1,2799,10),(6,11,2,520,0),
(7,1,1,17999,0),
(8,2,1,1499,10),(8,12,1,780,0),
(9,4,1,2299,0),
(10,6,3,599,5),(10,8,2,699,0),
(11,5,1,3499,0),
(12,9,1,499,0),(12,10,2,349,0),
(13,3,1,48990,10),
(14,7,1,2799,0),(14,8,1,699,0),
(15,11,3,520,0),(15,12,2,780,0);

-- Fill orders.total_amount from the items (UPDATE with JOIN)
UPDATE orders o
JOIN (SELECT order_id,
             ROUND(SUM(quantity*unit_price*(1-discount_pct/100)),2) AS amt
      FROM order_items GROUP BY order_id) t
  ON o.order_id = t.order_id
SET o.total_amount = t.amt;

INSERT INTO payments (order_id,payment_mode,payment_status,paid_at) VALUES
(1,'UPI','Success','2026-09-25 10:15:00'),
(2,'Credit Card','Success','2026-10-05 14:20:00'),
(3,'EMI','Success','2026-10-12 19:45:00'),
(4,'UPI','Success','2026-10-20 09:10:00'),
(5,'UPI','Refunded','2026-11-01 21:05:00'),
(6,'COD','Success','2026-11-07 12:00:00'),
(7,'Debit Card','Success','2026-11-05 11:30:00'),
(8,'UPI','Success','2026-11-08 22:15:00'),
(9,'Credit Card','Refunded','2026-11-10 16:40:00'),
(10,'COD','Success','2026-11-16 13:25:00'),
(11,'COD','Pending',NULL),
(12,'Net Banking','Success','2026-11-20 18:50:00'),
(13,'UPI','Success','2026-11-22 08:35:00'),
(14,'Credit Card','Success','2026-09-28 20:00:00'),
(15,'UPI','Success','2026-09-30 15:15:00');

INSERT INTO reviews (product_id,customer_id,rating,review_date) VALUES
(1,1,5,'2026-10-02'),(1,6,4,'2026-11-15'),(1,5,4,'2026-11-16'),
(2,1,4,'2026-10-03'),(2,3,5,'2026-11-12'),
(3,3,5,'2026-10-20'),
(4,2,3,'2026-10-12'),
(5,4,2,'2026-11-05'),
(6,2,4,'2026-10-14'),
(7,5,3,'2026-11-12'),
(8,3,4,'2026-11-14'),
(9,1,5,'2026-10-28'),
(10,1,4,'2026-10-28'),
(12,3,3,'2026-11-14');


/* =====================================================================
   LEVEL 1 : BASIC  -  SELECT, WHERE, ORDER BY, LIMIT
   ===================================================================== */

-- Q1. View all customers
SELECT * FROM customers;

-- Q2. Only selected columns with alias
SELECT name AS customer_name, city, state FROM customers;

-- Q3. Customers from Maharashtra
SELECT name, city FROM customers WHERE state = 'Maharashtra';

-- Q4. Flipkart Plus members
SELECT name, email FROM customers WHERE is_plus = 1;

-- Q5. Products costing more than Rs.5000
SELECT product_name, brand, price FROM products WHERE price > 5000;

-- Q6. Products priced between 500 and 3000
SELECT product_name, price FROM products WHERE price BETWEEN 500 AND 3000;

-- Q7. Products of selected brands (IN)
SELECT product_name, brand FROM products WHERE brand IN ('boAt','Puma','HP');

-- Q8. Pattern search: product names containing 'Shoe' or starting with 'A'
SELECT product_name FROM products
WHERE product_name LIKE '%Shoe%' OR product_name LIKE 'A%';

-- Q9. Top 5 most expensive products
SELECT product_name, price FROM products ORDER BY price DESC LIMIT 5;

-- Q10. Distinct cities our customers live in
SELECT DISTINCT city FROM customers ORDER BY city;

-- Q11. Orders that are Delivered AND above Rs.5000
SELECT order_id, customer_id, total_amount
FROM orders
WHERE order_status = 'Delivered' AND total_amount > 5000;

-- Q12. Payments still pending (NULL handling)
SELECT * FROM payments WHERE paid_at IS NULL;


/* =====================================================================
   LEVEL 2 : AGGREGATES  -  COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING
   ===================================================================== */

-- Q13. Basic KPIs of the business
SELECT COUNT(*)                 AS total_orders,
       SUM(total_amount)        AS total_revenue,
       ROUND(AVG(total_amount),2) AS avg_order_value,
       MAX(total_amount)        AS biggest_order,
       MIN(total_amount)        AS smallest_order
FROM orders;

-- Q14. Orders count by status
SELECT order_status, COUNT(*) AS orders
FROM orders GROUP BY order_status ORDER BY orders DESC;

-- Q15. Revenue by status (only delivered counts as real revenue)
SELECT order_status, SUM(total_amount) AS revenue
FROM orders GROUP BY order_status;

-- Q16. Number of customers per state
SELECT state, COUNT(*) AS customers
FROM customers GROUP BY state ORDER BY customers DESC;

-- Q17. Payment mode popularity
SELECT payment_mode, COUNT(*) AS uses
FROM payments GROUP BY payment_mode ORDER BY uses DESC;

-- Q18. Customers who placed more than 1 order (HAVING)
SELECT customer_id, COUNT(*) AS orders_placed
FROM orders GROUP BY customer_id HAVING COUNT(*) > 1;

-- Q19. Average rating per product (min 2 reviews)
SELECT product_id, COUNT(*) AS reviews, ROUND(AVG(rating),2) AS avg_rating
FROM reviews GROUP BY product_id HAVING COUNT(*) >= 2
ORDER BY avg_rating DESC;

-- Q20. Monthly order trend
SELECT DATE_FORMAT(order_date,'%Y-%m') AS month,
       COUNT(*) AS orders, SUM(total_amount) AS revenue
FROM orders GROUP BY DATE_FORMAT(order_date,'%Y-%m') ORDER BY month;


/* =====================================================================
   LEVEL 3 : JOINS
   ===================================================================== */

-- Q21. INNER JOIN: order list with customer name
SELECT o.order_id, c.name, o.order_date, o.order_status, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date;

-- Q22. Products with their category name
SELECT p.product_name, c.category_name, p.price
FROM products p
JOIN categories c ON c.category_id = p.category_id;

-- Q23. Full invoice view: 4-table join
SELECT o.order_id, c.name AS customer, p.product_name,
       oi.quantity, oi.unit_price, oi.discount_pct,
       ROUND(oi.quantity*oi.unit_price*(1-oi.discount_pct/100),2) AS line_total
FROM order_items oi
JOIN orders    o ON o.order_id    = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN products  p ON p.product_id  = oi.product_id
ORDER BY o.order_id;

-- Q24. LEFT JOIN: customers who NEVER ordered (target for marketing)
SELECT c.customer_id, c.name, c.city
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Q25. LEFT JOIN: products never sold
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.item_id IS NULL;

-- Q26. Category-wise revenue (net of discount)
SELECT cat.category_name,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)),2) AS revenue
FROM order_items oi
JOIN products   p   ON p.product_id   = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id
GROUP BY cat.category_name
ORDER BY revenue DESC;

-- Q27. Top 3 customers by lifetime spend (delivered orders only)
SELECT c.name, COUNT(o.order_id) AS orders, SUM(o.total_amount) AS spent
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_status = 'Delivered'
GROUP BY c.customer_id, c.name
ORDER BY spent DESC
LIMIT 3;

-- Q28. Revenue by payment mode (successful payments only)
SELECT pay.payment_mode, COUNT(*) AS orders, SUM(o.total_amount) AS revenue
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
WHERE pay.payment_status = 'Success'
GROUP BY pay.payment_mode ORDER BY revenue DESC;

-- Q29. City-wise revenue
SELECT c.city, COUNT(DISTINCT o.order_id) AS orders, SUM(o.total_amount) AS revenue
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.city ORDER BY revenue DESC;

-- Q30. Plus vs Non-Plus members: who spends more?
SELECT IF(c.is_plus=1,'Plus','Regular') AS member_type,
       COUNT(DISTINCT c.customer_id) AS customers,
       ROUND(AVG(o.total_amount),2)  AS avg_order_value
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.is_plus;

-- Q31. SELF JOIN: pairs of customers living in the same city
SELECT a.name AS customer_1, b.name AS customer_2, a.city
FROM customers a
JOIN customers b ON a.city = b.city AND a.customer_id < b.customer_id;


/* =====================================================================
   LEVEL 4 : SUBQUERIES & CASE
   ===================================================================== */

-- Q32. Products priced above the average price
SELECT product_name, price FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- Q33. Customers who have ordered an Electronics product (IN / subquery)
SELECT name FROM customers
WHERE customer_id IN (
    SELECT o.customer_id
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    JOIN categories c ON c.category_id = p.category_id
    WHERE c.category_name = 'Electronics');

-- Q34. Customers with NO orders using NOT EXISTS
SELECT name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- Q35. Orders bigger than the average order value
SELECT order_id, total_amount FROM orders
WHERE total_amount > (SELECT AVG(total_amount) FROM orders);

-- Q36. CASE: tag each order as Small / Medium / Large
SELECT order_id, total_amount,
       CASE WHEN total_amount < 1500  THEN 'Small'
            WHEN total_amount < 10000 THEN 'Medium'
            ELSE 'Large' END AS order_size
FROM orders;

-- Q37. CASE: stock alert for the warehouse team
SELECT product_name, stock_qty,
       CASE WHEN stock_qty < 10  THEN 'REORDER NOW'
            WHEN stock_qty < 100 THEN 'Low'
            ELSE 'OK' END AS stock_status
FROM products ORDER BY stock_qty;

-- Q38. Cancellation + return rate (conditional aggregation)
SELECT COUNT(*) AS total_orders,
       SUM(order_status='Cancelled') AS cancelled,
       SUM(order_status='Returned')  AS returned,
       ROUND(100*SUM(order_status IN ('Cancelled','Returned'))/COUNT(*),2) AS loss_pct
FROM orders;

-- Q39. Best product in every category (correlated subquery)
SELECT p.category_id, p.product_name, p.price
FROM products p
WHERE p.price = (SELECT MAX(price) FROM products WHERE category_id = p.category_id);


/* =====================================================================
   LEVEL 5 : CTE, WINDOW FUNCTIONS (MySQL 8+)
   ===================================================================== */

-- Q40. CTE: customer lifetime value, then segment them
WITH clv AS (
    SELECT customer_id, SUM(total_amount) AS spent
    FROM orders WHERE order_status = 'Delivered'
    GROUP BY customer_id
)
SELECT c.name, clv.spent,
       CASE WHEN clv.spent >= 20000 THEN 'Gold'
            WHEN clv.spent >= 5000  THEN 'Silver'
            ELSE 'Bronze' END AS segment
FROM clv JOIN customers c ON c.customer_id = clv.customer_id
ORDER BY clv.spent DESC;

-- Q41. RANK products by revenue
SELECT p.product_name,
       ROUND(SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)),2) AS revenue,
       RANK() OVER (ORDER BY SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)) DESC) AS rnk
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name;

-- Q42. Top-1 product in each category (ROW_NUMBER + PARTITION)
WITH prod_rev AS (
    SELECT cat.category_name, p.product_name,
           SUM(oi.quantity*oi.unit_price*(1-oi.discount_pct/100)) AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    JOIN categories cat ON cat.category_id = p.category_id
    GROUP BY cat.category_name, p.product_id, p.product_name
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS rn
    FROM prod_rev
)
SELECT category_name, product_name, ROUND(revenue,2) AS revenue
FROM ranked WHERE rn = 1;

-- Q43. Running total of daily revenue
SELECT order_date, SUM(total_amount) AS daily_revenue,
       SUM(SUM(total_amount)) OVER (ORDER BY order_date) AS running_revenue
FROM orders GROUP BY order_date ORDER BY order_date;

-- Q44. Each customer's orders with the previous order date (LAG)
SELECT customer_id, order_id, order_date,
       LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
       DATEDIFF(order_date,
                LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)) AS days_gap
FROM orders ORDER BY customer_id, order_date;

-- Q45. Month-over-month revenue growth %
WITH monthly AS (
    SELECT DATE_FORMAT(order_date,'%Y-%m') AS ym, SUM(total_amount) AS revenue
    FROM orders WHERE order_status NOT IN ('Cancelled','Returned')
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
)
SELECT ym, revenue,
       LAG(revenue) OVER (ORDER BY ym) AS prev_month,
       ROUND(100*(revenue - LAG(revenue) OVER (ORDER BY ym))
             / LAG(revenue) OVER (ORDER BY ym),2) AS growth_pct
FROM monthly;

-- Q46. Each order's share of its customer's total spend
SELECT customer_id, order_id, total_amount,
       ROUND(100*total_amount/SUM(total_amount) OVER (PARTITION BY customer_id),2) AS pct_of_customer
FROM orders;

-- Q47. Repeat customers vs one-time customers
WITH cnt AS (SELECT customer_id, COUNT(*) AS n FROM orders GROUP BY customer_id)
SELECT IF(n>1,'Repeat','One-time') AS customer_type, COUNT(*) AS customers
FROM cnt GROUP BY IF(n>1,'Repeat','One-time');

-- Q48. Customers who bought but never reviewed (conversion gap)
SELECT DISTINCT c.name
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN reviews r ON r.customer_id = c.customer_id
WHERE r.review_id IS NULL;

-- Q49. Frequently bought together (product pairs in the same order)
SELECT p1.product_name AS product_a, p2.product_name AS product_b, COUNT(*) AS times_together
FROM order_items a
JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
JOIN products p1 ON p1.product_id = a.product_id
JOIN products p2 ON p2.product_id = b.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_together DESC;


/* =====================================================================
   LEVEL 6 : DML + VIEWS + INDEX + TRANSACTION + PROCEDURE + TRIGGER
   ===================================================================== */

-- Q50. UPDATE: Flipkart "Big Billion Days" - 10% price cut on Electronics
UPDATE products SET price = ROUND(price*0.90,2)
WHERE category_id = (SELECT category_id FROM categories WHERE category_name='Electronics');
SELECT product_name, price FROM products WHERE category_id = 1;

-- Q51. DELETE: remove reviews with rating 1 (none here, safe demo)
DELETE FROM reviews WHERE rating = 1;

-- Q52. VIEW: reusable sales report
CREATE OR REPLACE VIEW vw_sales_report AS
SELECT o.order_id, o.order_date, c.name AS customer, c.city,
       p.product_name, cat.category_name, oi.quantity,
       ROUND(oi.quantity*oi.unit_price*(1-oi.discount_pct/100),2) AS line_total,
       o.order_status
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_id = oi.product_id
JOIN categories cat ON cat.category_id = p.category_id;

SELECT * FROM vw_sales_report WHERE city = 'Pune';
SELECT category_name, SUM(line_total) AS revenue FROM vw_sales_report GROUP BY category_name;

-- Q53. INDEX: speed up the frequent "orders by customer" lookup
CREATE INDEX idx_orders_customer ON orders(customer_id);
EXPLAIN SELECT * FROM orders WHERE customer_id = 1;

-- Q54. TRANSACTION: place an order safely (all or nothing)
START TRANSACTION;
  INSERT INTO orders (customer_id, order_date, order_status) VALUES (8, CURDATE(), 'Placed');
  SET @new_order = LAST_INSERT_ID();
  INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct)
         VALUES (@new_order, 9, 2, 499, 0);
  UPDATE orders SET total_amount = 2*499 WHERE order_id = @new_order;
COMMIT;      -- use ROLLBACK; instead of COMMIT; to undo everything
SELECT * FROM orders WHERE order_id = @new_order;

-- Q55. STORED PROCEDURE: get a customer's order history
DROP PROCEDURE IF EXISTS sp_customer_orders;
DELIMITER $$
CREATE PROCEDURE sp_customer_orders(IN p_customer_id INT)
BEGIN
    SELECT o.order_id, o.order_date, o.order_status, o.total_amount
    FROM orders o
    WHERE o.customer_id = p_customer_id
    ORDER BY o.order_date DESC;
END $$
DELIMITER ;

CALL sp_customer_orders(1);

-- Q56. TRIGGER: auto-reduce stock when an item is ordered
DROP TRIGGER IF EXISTS trg_reduce_stock;
DELIMITER $$
CREATE TRIGGER trg_reduce_stock
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE products SET stock_qty = stock_qty - NEW.quantity
    WHERE product_id = NEW.product_id;
END $$
DELIMITER ;

-- Test the trigger: stock of product 10 before and after
SELECT product_id, stock_qty FROM products WHERE product_id = 10;
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct)
VALUES (11, 10, 2, 349, 0);
SELECT product_id, stock_qty FROM products WHERE product_id = 10;   -- reduced by 2


/* =====================================================================
   BONUS : INTERVIEW-STYLE BUSINESS QUESTIONS
   ===================================================================== */

-- B1. Second highest priced product
SELECT product_name, price FROM products
ORDER BY price DESC LIMIT 1 OFFSET 1;

-- B2. Customers whose last order was more than 30 days ago (churn risk)
SELECT c.name, MAX(o.order_date) AS last_order,
       DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_inactive
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
HAVING DATEDIFF(CURDATE(), MAX(o.order_date)) > 30;

-- B3. Delivered orders paid via COD (cash-handling load)
SELECT o.order_id, o.total_amount
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_mode = 'COD' AND o.order_status = 'Delivered';

-- B4. Refund liability: money to return to customers
SELECT SUM(o.total_amount) AS refund_amount
FROM orders o JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_status = 'Refunded';

-- B5. Average rating by brand with minimum 1 review
SELECT p.brand, ROUND(AVG(r.rating),2) AS avg_rating, COUNT(*) AS reviews
FROM reviews r JOIN products p ON p.product_id = r.product_id
GROUP BY p.brand ORDER BY avg_rating DESC;

/* ================================= END ================================= */
