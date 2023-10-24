SELECT *
FROM members

SELECT * 
FROM menu

SELECT * 
FROM sales

-- What is the total amount each customer spent at the restaurant?
SELECT 
customer_id, 
SUM(price) AS 'Total Purchase'
FROM sales as s
JOIN menu as me on me.product_id = s.product_id
GROUP BY customer_id
ORDER BY customer_id

-- How many days has each customer visited the restaurant?
SELECT 
customer_id, 
COUNT(DISTINCT(order_date)) AS 'Amount of Visits'
FROM sales
GROUP BY customer_id

-- What was the first item from the menu purchased by each customer?
SELECT 
customer_id, 
product_name, 
MIN(order_date) AS 'first order'
FROM sales as s
JOIN menu as me on me.product_id = s.product_id
WHERE order_date = '2021-01-01'
GROUP BY customer_id, product_name
ORDER BY customer_id

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
product_name, 
COUNT(*) AS total_purchase
FROM sales as s
JOIN menu as me on me.product_id = s.product_id
GROUP BY product_name
ORDER BY total_purchase DESC
LIMIT 1

-- Which item was the most popular for each customer?
SELECT 
customer_id, 
product_name, 
COUNT(*) AS 'Amount Purchased',
DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS 'Ranking'
FROM sales as s
JOIN menu as me on me.product_id = s.product_id
GROUP BY customer_id, product_name
ORDER BY customer_id


-- Which item was purchased first by the customer after they became a member?
WITH Firstpurchase AS (
SELECT 
m.customer_id,
join_date,
me.product_id,
order_date,
product_name,
ROW_NUMBER() OVER(PARTITION BY m.customer_id ORDER BY order_date) AS Purchase_Rank
FROM members as m
JOIN sales as s on s.customer_id = m.customer_id
JOIN menu as me on me.product_id = s.product_id
WHERE order_date > join_date
)
SELECT 
customer_id, 
product_name AS First_item_purchased
FROM Firstpurchase
WHERE Purchase_Rank = 1

-- Which item was purchased just before the customer became a member?
WITH Firstpurchase AS (
SELECT 
m.customer_id,
join_date,
me.product_id,
order_date,
product_name,
ROW_NUMBER() OVER(PARTITION BY m.customer_id ORDER BY order_date) AS Purchase_Rank
FROM members as m
JOIN sales as s on s.customer_id = m.customer_id
JOIN menu as me on me.product_id = s.product_id
WHERE order_date < join_date
)
SELECT 
customer_id, 
product_name AS First_item_purchased
FROM Firstpurchase
WHERE Purchase_Rank = 1

-- What is the total items and amount spent for each member before they became a member?
SELECT 
s.customer_id,
COUNT(s.product_id) AS Total_items,
SUM(price) AS Total_amount_spent
FROM members as m
JOIN sales as s on s.customer_id = m.customer_id
JOIN menu as me on me.product_id = s.product_id
WHERE order_date < join_date
GROUP BY customer_id

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
customer_id,
SUM(CASE
WHEN product_name = 'sushi' THEN price * 10 * 2
ELSE price * 10
END) AS Multiplier_points
FROM menu as me
JOIN sales as s on s.product_id = me.product_id
GROUP BY customer_id

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
SELECT 
s.customer_id,
SUM(CASE
	WHEN order_date BETWEEN m.join_date AND DATE_ADD('day', 6, m.join_date) THEN price * 10 * 2
	WHEN product_name = 'sushi' THEN price * 10 * 2
	ELSE price * 10
END) as Points, 
FROM menu as me
JOIN sales as s on s.product_id = me.product_id
JOIN members as m on m.customer_id = s.customer_id
WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id


-- Bonus questions
-- 1
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN s.order_date >= me.join_date THEN 'Y' 
ELSE 'N' 
END as member
FROM sales as s
JOIN menu m ON s.product_id = m.product_id
JOIN members me ON s.customer_id = me.customer_id
ORDER BY s.customer_id, s.order_date;

-- 2
WITH customer_membership AS (
SELECT
s.customer_id,
s.order_date,
product_name,
price,
CASE
	WHEN order_date >= join_date THEN 'Y'
	WHEN order_date < join_date THEN 'N'
	ELSE 'N' 
END AS 'Member'
FROM sales as s
JOIN menu as m on m.product_id = s.product_id
JOIN members as mem on mem.customer_id = s.customer_id
ORDER BY customer_id
)
SELECT 
*
,CASE
	WHEN member = 'N' THEN 'NULL'
    ELSE RANK () OVER(PARTITION BY s.customer_id, member ORDER BY order_date) 
END AS 'Rank'
FROM customer_membership
ORDER BY s.customer_id, order_date
