CREATE database Case_Study;
USE Case_Study;

CREATE TABLE sales (
  customer_id VARCHAR(2),
  order_date DATE,
  product_id INTEGER
);


INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

-- Case Study Questions
-- 1)What is the total amount each customer spent at the restaurant?
SELECT s.customer_id Customer, sum(m.price) Amount_Spent  FROM sales s INNER JOIN menu m ON s.product_id = m.product_id GROUP BY s.customer_id;

-- 2)How many days has each customer visited the restaurant?
SELECT customer_id Customer, Count(Distinct(order_date)) Num_days FROM sales GROUP BY customer_id;

-- 3)What was the first item from the menu purchased by each customer?
SELECT n.* FROM
(SELECT s.customer_id Customer, m.product_name Product, 
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) first_item_purchased
FROM sales s
INNER JOIN menu m
ON s.product_id=m.product_id) n
WHERE n.first_item_purchased=1;

-- 4)What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name product, count(m.product_name) count
FROM menu m
INNER JOIN sales s
ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY count(m.product_name) DESC LIMIT 1;

-- 5)Which item was the most popular for each customer?
SELECT customer_id, product_name 
FROM
(SELECT s.customer_id, m.product_name, count(m.product_name) order_count,
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY count(m.product_name) DESC) rn
FROM sales s
INNER JOIN menu m
ON m.product_id = s.product_id
GROUP BY s.customer_id,  m.product_name) x
WHERE x.rn=1;

-- 6)Which item was purchased first by the customer after they became a member?
SELECT customer_id, product_name FROM 
(SELECT s.customer_id, m.product_name, s.order_date,mb.join_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) rnk 
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date>mb.join_date) x
WHERE x.rnk=1;

-- 7)Which item was purchased just before the customer became a member?
SELECT customer_id, product_name FROM 
(SELECT s.customer_id, m.product_name, s.order_date,mb.join_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) rnk 
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date<mb.join_date) x
WHERE x.rnk=1;

-- 8)What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, count(product_name) total_items, sum(m.price) amount_spent
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date<mb.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9)If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT p.customer_id, sum(p.points) total_points FROM
(SELECT s.customer_id, m.product_name, m.price,
CASE 
	WHEN m.product_name='sushi' THEN m.price*10*2
    ELSE m.price*10
    END points
FROM sales s
JOIN menu m
ON s.product_id=m.product_id) p
GROUP BY p.customer_id;


-- 10)In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? 
SELECT t.customer_id, sum(t.points) total_points FROM
(SELECT s.customer_id, m.product_name, m.price, s.order_date, mb.join_date,
CASE 
    WHEN s.order_date BETWEEN mb.join_date AND DATE_ADD(s.order_date, INTERVAL 7 Day) THEN  m.price*10*2  
    ELSE(CASE WHEN m.product_name='sushi' THEN m.price*10*2 ELSE m.price*10 END)
    END points
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date<'2021-02-01') t
GROUP BY t.customer_id ORDER BY total_points DESC;

-- 11) Determine the name and price of the product ordered by each customer on all order dates and find out whether the customers was a member on order date?
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
	WHEN s.order_date>=mb.join_date THEN 'Yes' ELSE 'No' END is_member
FROM sales s
JOIN menu m
ON m.product_id = s.product_id
LEFT JOIN members mb
ON s.customer_id = mb.customer_id;

-- 12) Rank the previous output based on the order_date for each customer. Display NULL if customer was not a member when a dish was ordered. 

SELECT t.*,
CASE 
	WHEN t.is_member='Yes' THEN RANK() OVER(PARTITION BY t.customer_id,t.is_member ORDER BY s.order_date) ELSE 'NULL' END ranking
FROM
(SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
	WHEN s.order_date>=mb.join_date THEN 'Yes' ELSE 'No' END is_member
FROM sales s
JOIN menu m
ON m.product_id = s.product_id
LEFT JOIN members mb
ON s.customer_id = mb.customer_id) t;