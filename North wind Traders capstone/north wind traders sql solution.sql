create database capstone;
use capstone;
select * from orders;
select * from categories;
select * from customers;
select * from orderdetails;
select * from orders;
select * from products;
select * from shippers;
select * from suppliers;
select * from employees;




1.	What is the average number of orders per customer? Are there high-value repeat customers?
2.	How do customer order patterns vary by city or country?
3.	Can we cluster customers based on total spend, order count, and preferred categories?
4.	Which product categories or products contribute most to order revenue? 5 .Are there any correlations between orders and customer location or product category?
5.	How frequently do different customer segments place orders?
6.	What is the geographic and title-wise distribution of employees?
7.	What trends can we observe in hire dates across employee titles?
8.	What patterns exist in employee title and courtesy title distributions?
9.	Are there correlations between product pricing, stock levels, and sales performance?
10.	How does product demand change over months or seasons?
11.	Can we identify anomalies in product sales or revenue performance?
12.	Are there any regional trends in supplier distribution and pricing?
13.	How are suppliers distributed across different product categories?
14.	How do supplier pricing and categories relate across different regions?



SELECT 
    AVG(order_count) AS avg_orders_per_customer
FROM (
    SELECT 
        CustomerID,
        COUNT(OrderID) AS order_count
    FROM orders
    GROUP BY CustomerID
) AS customer_orders;


SELECT 
    o.CustomerID,
    COUNT(DISTINCT o.OrderID) AS total_orders,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_spent
FROM orders o
JOIN orderdetails od
    ON o.OrderID = od.OrderID
GROUP BY o.CustomerID
HAVING total_orders > 1
ORDER BY total_spent DESC
LIMIT 5;



use capstone;
SELECT 
    o.ShipCountry AS Country,
    COUNT(DISTINCT o.CustomerID) AS total_customers,
    COUNT(o.OrderID) AS total_orders,
    ROUND(COUNT(o.OrderID) / COUNT(DISTINCT o.CustomerID), 2) 
        AS avg_orders_per_customer
FROM orders o
GROUP BY o.ShipCountry
ORDER BY avg_orders_per_customer DESC;


use capstone;
SELECT 
    o.CustomerID,
    COUNT(DISTINCT o.OrderID) AS total_orders,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_spend
FROM orders o
JOIN orderdetails od
    ON o.OrderID = od.OrderID
GROUP BY o.CustomerID;


use capstone;
SELECT 
    t.CustomerID,
    t.CategoryID
FROM (
    SELECT 
        o.CustomerID,
        p.CategoryID,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS category_spend,
        RANK() OVER (
            PARTITION BY o.CustomerID 
            ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC
        ) AS rnk
    FROM orders o
    JOIN orderdetails od
        ON o.OrderID = od.OrderID
    JOIN products p
        ON od.ProductID = p.ProductID
    GROUP BY o.CustomerID, p.CategoryID
) t
WHERE t.rnk = 1;


SELECT 
    c.CustomerID,
    c.total_orders,
    c.total_spend,
    pc.CategoryID AS preferred_category,
    CASE
        WHEN c.total_spend > 50000 AND c.total_orders > 50 THEN 'High Value – Loyal'
        WHEN c.total_spend > 20000 AND c.total_orders > 20 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_cluster
FROM (
    SELECT 
        o.CustomerID,
        COUNT(DISTINCT o.OrderID) AS total_orders,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS total_spend
    FROM orders o
    JOIN orderdetails od
        ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
) c
LEFT JOIN (
    SELECT 
        t.CustomerID,
        t.CategoryID
    FROM (
        SELECT 
            o.CustomerID,
            p.CategoryID,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS category_spend,
            RANK() OVER (
                PARTITION BY o.CustomerID 
                ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC
            ) AS rnk
        FROM orders o
        JOIN orderdetails od
            ON o.OrderID = od.OrderID
        JOIN products p
            ON od.ProductID = p.ProductID
        GROUP BY o.CustomerID, p.CategoryID
    ) t
    WHERE t.rnk = 1
) pc
ON c.CustomerID = pc.CustomerID;


SELECT 
    c.CustomerID,
    c.total_orders,
    ROUND(c.total_spend, 2) AS total_spend,
    cat.CategoryName AS preferred_category,
    CASE
        WHEN c.total_spend > 50000 AND c.total_orders > 50 THEN 'High Value – Loyal'
        WHEN c.total_spend > 20000 AND c.total_orders > 20 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_cluster
FROM (
    SELECT 
        o.CustomerID,
        COUNT(DISTINCT o.OrderID) AS total_orders,
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS total_spend
    FROM orders o
    JOIN orderdetails od
        ON o.OrderID = od.OrderID
    GROUP BY o.CustomerID
) c
LEFT JOIN (
    SELECT 
        t.CustomerID,
        t.CategoryID
    FROM (
        SELECT 
            o.CustomerID,
            p.CategoryID,
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) AS category_spend,
            RANK() OVER (
                PARTITION BY o.CustomerID 
                ORDER BY SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) DESC
            ) AS rnk
        FROM orders o
        JOIN orderdetails od
            ON o.OrderID = od.OrderID
        JOIN products p
            ON od.ProductID = p.ProductID
        GROUP BY o.CustomerID, p.CategoryID
    ) t
    WHERE t.rnk = 1
) pc
    ON c.CustomerID = pc.CustomerID
LEFT JOIN categories cat
    ON pc.CategoryID = cat.CategoryID;
    
    
    
    SELECT
    c.CategoryName,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_revenue
FROM orderdetails od
JOIN products p
    ON od.ProductID = p.ProductID
JOIN categories c
    ON p.CategoryID = c.CategoryID
GROUP BY c.CategoryName
ORDER BY total_revenue DESC;




SELECT 
    Country,
    Title,
    COUNT(EmployeeID) AS total_employees
FROM employees
GROUP BY Country, Title
ORDER BY Country, total_employees DESC;


use capstone;

SELECT 
    Title,
    ROUND(AVG(YEAR(HireDate)), 0) AS avg_hire_year,
    COUNT(EmployeeID) AS total_employees
FROM employees
GROUP BY Title
ORDER BY avg_hire_year;



SELECT 
    YEAR(HireDate) AS hire_year,
    Title,
    COUNT(EmployeeID) AS employees_hired
FROM employees
GROUP BY hire_year, Title
ORDER BY hire_year, Title;






SELECT 
    Title,
    MIN(HireDate) AS earliest_hire,
    MAX(HireDate) AS latest_hire
FROM employees
GROUP BY Title;


