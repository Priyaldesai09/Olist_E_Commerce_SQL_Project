SELECT DATABASE();
USE olist;
SHOW tables;

SELECT * FROM	olist_customers_dataset;
SHOW VARIABLES LIKE 'datadir';

SELECT * 
FROM information_schema.tables 
WHERE TABLE_NAME LIKE '%olist%';

SHOW VARIABLES LIKE 'datadir';
RENAME TABLE `olist_customers_dataset - copy` TO olist_customers_dataset_copy;


SELECT COUNT(*) FROM olist_customers_dataset_copy;
SELECT COUNT(*) FROM olist_orders_dataset;
SELECT COUNT(*) FROM olist_products_dataset;
SELECT COUNT(*) FROM olist_order_items_dataset;

-- Customer Analysis--
/* 1)  Find which State has the highest Customers and the Lowest ones*/

SELECT * FROM olist_customers_dataset_copy;

SELECT customer_state, COUNT(customer_id) AS Customers
FROM olist_customers_dataset_copy
GROUP BY customer_state
ORDER BY Customers DESC;

-- 2)  Find whcih city has the lowest customers--
SELECT customer_city, COUNT(customer_id) AS Total_Customers
FROM olist_customers_dataset_copy
GROUP BY customer_city
ORDER BY Total_Customers ASC;


-- Order Analysis--
-- Check for the datatype of Order Delivery Dates--
SELECT order_delivered_customer_date, order_estimated_delivery_date
FROM olist_orders_dataset
LIMIT 5;

-- 3) How many orders got delayed--
SELECT * FROM olist_orders_dataset;
SELECT COUNT(order_id) AS Total_Orders_Delayed
FROM olist_orders_dataset
WHERE TRIM(order_delivered_customer_date) IS NOT NULL
	AND TRIM(order_estimated_delivery_date) IS NOT NULL
	AND TRIM(order_delivered_customer_date) <> ''
	AND TRIM(order_estimated_delivery_date) <> ''
	AND DATEDIFF(
			STR_TO_DATE (order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'),
			STR_TO_DATE (order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s')
            ) > 0 ;
-- 4) Find how many orders got cancelled nad delivered--
SELECT COUNT(order_id) AS Total_Orderes, order_status
FROM olist_orders_dataset
GROUP BY order_status;
            
-- 5)  Find how many orders get delayed out of delivered, through implemented Subquery --
SELECT 
	COUNT(order_id) AS Total_Orders_Delayed,
    (SELECT COUNT(order_id)
    FROM olist_orders_dataset
    WHERE order_status = 'delivered') AS Total_Delivered_Orders,
    (COUNT(order_id)*100/
		(SELECT COUNT(order_id)
        FROM olist_orders_dataset
        WHERE order_status = 'delivered')) AS Percentage_Delayed
FROM olist_orders_dataset
WHERE order_status = 'delivered'
	AND TRIM(order_delivered_customer_date) IS NOT NULL
    AND TRIM(order_estimated_delivery_date) IS NOT NULL
    AND TRIM(order_delivered_customer_date) <> ''
	AND TRIM(order_estimated_delivery_date) <> ''
	AND DATEDIFF(
			STR_TO_DATE (order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'),
			STR_TO_DATE (order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s')
            ) > 0 ;
-- 6% Delayed in Delievering Orders is not that bad--

-- Combine Customer and Order dataset --

-- Implemented INNER JOIN --
SELECT 
	c.customer_state,
    c.customer_zip_code_prefix,
    c.customer_city,
    o.order_id,
    o.customer_id,
    o.order_status
FROM olist_customers_dataset_copy c
INNER JOIN olist_orders_dataset o 
ON o.customer_id=c.customer_id;

-- For that need to create CTE for making further analysis faster--
WITH Customer_Orders_Table AS
	(SELECT 
	c.customer_state,
    c.customer_zip_code_prefix,
    c.customer_city,
    o.order_id,
    o.customer_id,
    o.order_status
FROM olist_customers_dataset_copy c
INNER JOIN olist_orders_dataset o 
ON o.customer_id=c.customer_id)
SELECT*FROM Customer_Orders_Table;

-- 6)  Highest Cancelled Orders in which State--
WITH Customer_Orders_Table AS
	(SELECT 
	c.customer_state,
    c.customer_zip_code_prefix,
    c.customer_city,
    o.order_id,
    o.customer_id,
    o.order_status
FROM olist_customers_dataset_copy c
INNER JOIN olist_orders_dataset o 
ON o.customer_id=c.customer_id)
SELECT customer_state, COUNT(order_id), order_status
FROM Customer_Orders_Table
GROUP BY customer_state, order_status;


-- Now applying conditions to check highest cancellation in which State --
   
WITH Customer_Orders_Table AS
	(SELECT 
	c.customer_state,
    c.customer_zip_code_prefix,
    c.customer_city,
    o.order_id,
    o.customer_id,
    o.order_status
FROM olist_customers_dataset_copy c
INNER JOIN olist_orders_dataset o 
ON o.customer_id=c.customer_id)
SELECT customer_state, COUNT(order_id) AS Total_Orders_Canceled, order_status
FROM Customer_Orders_Table
WHERE order_status = 'canceled'
GROUP BY customer_state, order_status
ORDER BY  Total_Orders_canceled DESC;

-- Product Analysis--
SELECT 
	p.product_id, 
	p.product_category_name,
	pt.product_category_name_english
FROM olist_products_dataset AS p
INNER JOIN product_category_name_translation AS pt
	ON p.product_category_name = pt.product_category_name;
    
-- Check for the product_category_name Datatype as it is creating error--

DESCRIBE product_category_name_translation;

-- Modify the Datatype --
ALTER TABLE product_category_name_translation CHANGE COLUMN `ï»¿product_category_name` product_category_name VARCHAR(255);
DESCRIBE product_category_name_translation

-- Rerun the above Product Analysis Query--
-- problem statements
-- 7)  Which product has highest sold-- Top Selling Products--
-- 8)  Join Order Item Table to Product dataset table--

-- 7) Create CTE for Products having Category Name in English for further analysis --
WITH product_cte AS (
    SELECT
        p.product_id,
        p.product_category_name,
        pt.product_category_name_english
    FROM olist_products_dataset AS p
    INNER JOIN product_category_name_translation AS pt
        ON p.product_category_name = pt.product_category_name
)
SELECT * FROM product_cte;

-- 8) Top selling products --
-- for that first we need to connect product_cte table to order item dataset table to get the Product Category Name in English --

WITH product_cte AS (
    SELECT
        p.product_id,
        p.product_category_name,
        pt.product_category_name_english
    FROM olist_products_dataset AS p
    INNER JOIN product_category_name_translation AS pt
        ON p.product_category_name = pt.product_category_name
)
SELECT 
	pc.product_category_name_english,
    oi.product_id,
    COUNT(oi.product_id) AS Total_Products_Sold
FROM product_cte AS pc
INNER JOIN  olist_order_items_dataset AS oi
ON pc.product_id = oi.product_id
GROUP BY pc.product_category_name_english, oi.product_id
ORDER BY Total_Products_Sold DESC;

-- 9) Which are the products sold highest in What State and City--
WITH product_cte AS(
	SELECT
		p.product_id,
        p.product_category_name,
        pt.product_category_name_english
	FROM olist_products_dataset AS p
    INNER JOIN product_category_name_translation AS pt
    ON p.product_category_name = pt.product_category_name
)
SELECT 
	c.customer_state,
    c.customer_city,
    pc.product_category_name_english,
    oi.product_id,
    COUNT(oi.product_id) AS Total_Products_Sold
FROM product_cte AS pc
INNER JOIN olist_order_items_dataset AS oi
ON pc.product_id = oi.product_id
INNER JOIN olist_orders_dataset AS o
ON oi.order_id = o.order_id
INNER JOIN olist_customers_dataset_copy AS c
ON o.customer_id = c.customer_id
GROUP BY c.customer_city, c.customer_state, pc.product_category_name_english, oi.product_id
ORDER BY Total_Products_Sold DESC;
-- Conclusion : SP and RJ are the states whob has highest buying power for olist products--

-- 10) Customer Segmentation to identify the repeat customers/one time customers to develop Market and Retention Strategies--

WITH customers_orders_count AS(
	SELECT 
		customer_id,
        COUNT (order_id) AS Total_Orders
	FROM olist_orders_dataset
    GROUP BY customer_id
),

total_customers AS (
	SELECT COUNT(*) AS total_customer_count
    FROM customers_orders_count
)
SELECT 
	CASE
		WHEN Total_Orders = 1 THEN 'One Time Customer'
        ELSE 'Repeat Customer'
	END AS customer_type,
    COUNT(customer_id) AS customer_count,
    ROUND(COUNT(customer_id)*100 / tc.total_customer_count, 2) AS Category_Percentage
FROM customers_orders_count
CROSS JOIN total_customers AS tc
GROUP BY customer_type;

		
    

