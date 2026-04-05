SELECT 
    o.CustomerID,
    COUNT(o.orderid) AS total_orders,
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_spend
FROM orders o
JOIN order_details od
    ON o.orderid = od.orderid
GROUP BY o.CustomerID
HAVING total_orders >= 20 
   AND total_spend >= 40000
ORDER BY o.CustomerID;   

-- Q2
SELECT 
    c.Country,
    c.City,
    
    COUNT(DISTINCT c.CustomerID) AS total_customers,
    COUNT(o.OrderID) AS total_orders,
    
    -- Total revenue (rounded)
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_revenue,
    
    -- Avg order value (rounded)
    ROUND(
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) 
        / COUNT(DISTINCT o.OrderID), 
    2) AS avg_order_value,
    
    -- Orders per customer (rounded)
    ROUND(
        COUNT(o.OrderID) * 1.0 / COUNT(DISTINCT c.CustomerID), 
    2) AS avg_orders_per_customer

FROM customers c
JOIN orders o 
    ON c.CustomerID = o.CustomerID
JOIN order_details od 
    ON o.OrderID = od.OrderID

GROUP BY c.Country, c.City
ORDER BY total_revenue DESC;

-- Q3
SELECT *
FROM (
    SELECT 
        o.CustomerID,
        c.CategoryName,
        COUNT(*) AS total_count,
        
        ROW_NUMBER() OVER (
            PARTITION BY o.CustomerID 
            ORDER BY COUNT(*) DESC
        ) AS rn
        
    FROM orders o
    JOIN order_details od 
        ON o.OrderID = od.OrderID
    JOIN products p 
        ON od.ProductID = p.ProductID
    JOIN categories c 
        ON p.CategoryID = c.CategoryID
        
    GROUP BY o.CustomerID, c.CategoryName
) t
WHERE rn = 1
ORDER BY total_count DESC;   

-- Q4
SELECT 
    'Category' AS analysis_type,
    c.CategoryName AS name,
    NULL AS location,
    
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_revenue,
    SUM(od.Quantity) AS total_quantity,
    NULL AS total_orders,
    
    ROUND(
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) * 100.0 /
        (SELECT SUM(UnitPrice * Quantity * (1 - Discount)) FROM order_details),
    2) AS contribution_percent

FROM order_details od
JOIN products p ON od.ProductID = p.ProductID
JOIN categories c ON p.CategoryID = c.CategoryID

GROUP BY c.CategoryName


UNION ALL


SELECT 
    'Product' AS analysis_type,
    p.ProductName AS name,
    NULL AS location,
    
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_revenue,
    SUM(od.Quantity) AS total_quantity,
    NULL AS total_orders,
    
    ROUND(
        SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) * 100.0 /
        (SELECT SUM(UnitPrice * Quantity * (1 - Discount)) FROM order_details),
    2) AS contribution_percent

FROM order_details od
JOIN products p ON od.ProductID = p.ProductID

GROUP BY p.ProductName


UNION ALL


SELECT 
    'Location_Category' AS analysis_type,
    c.CategoryName AS name,
    cu.Country AS location,
    
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_revenue,
    SUM(od.Quantity) AS total_quantity,
    COUNT(DISTINCT o.OrderID) AS total_orders,
    
    NULL AS contribution_percent

FROM customers cu
JOIN orders o ON cu.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
JOIN products p ON od.ProductID = p.ProductID
JOIN categories c ON p.CategoryID = c.CategoryID

GROUP BY cu.Country, c.CategoryName


ORDER BY analysis_type, total_revenue DESC;

-- Q5
WITH base AS (
    SELECT 
        c.Country,
        c.City,
        cat.CategoryName,
        p.ProductID,
        
        COUNT(DISTINCT o.OrderID) AS order_count
        
    FROM orders o
    JOIN customers c USING (CustomerID)
    JOIN order_details od USING (OrderID)
    JOIN products p USING (ProductID)
    JOIN categories cat USING (CategoryID)

    GROUP BY 
        c.Country, c.City, cat.CategoryName, p.ProductID
),

-- Step 1: Top 3 Cities per Country
city_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Country 
            ORDER BY order_count DESC
        ) AS city_rank
    FROM base
),

-- Step 2: Top 3 Categories per City
category_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Country, City 
            ORDER BY order_count DESC
        ) AS category_rank
    FROM city_ranked
    WHERE city_rank <= 3
),

-- Step 3: Top 3 Products per Category
product_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Country, City, CategoryName 
            ORDER BY order_count DESC
        ) AS product_rank
    FROM category_ranked
    WHERE category_rank <= 3
)

SELECT *
FROM product_ranked
WHERE product_rank <= 3
ORDER BY Country, City, CategoryName, order_count DESC;

-- Q6
SELECT 
    e.Country,
    e.City,
    e.Title,
    
    COUNT(*) AS total_employees

FROM employees e

GROUP BY 
    e.Country,
    e.City,
    e.Title

ORDER BY 
    e.Country,
    e.City,
    total_employees DESC;
    
    -- Q7
    SELECT 
    YEAR(HireDate) AS hire_year,
    Title,
    
    COUNT(*) AS total_hires

FROM employees

GROUP BY 
    YEAR(HireDate),
    Title

ORDER BY 
    hire_year,
    total_hires DESC;
    
    -- Q8
    SELECT 
    Title,
    TitleOfCourtesy,
    
    COUNT(*) AS total_employees

FROM employees

GROUP BY 
    Title,
    TitleOfCourtesy

ORDER BY 
    Title,
    total_employees DESC;
    
    -- Q9
    SELECT 
    p.ProductID,
    p.ProductName,
    
    p.UnitPrice AS price,
    p.UnitsInStock AS stock,
    
    SUM(od.Quantity) AS total_quantity_sold,
    
    ROUND(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 2) AS total_revenue

FROM products p
LEFT JOIN order_details od 
    ON p.ProductID = od.ProductID

GROUP BY 
    p.ProductID,
    p.ProductName,
    p.UnitPrice,
    p.UnitsInStock

ORDER BY total_revenue DESC;

-- Q10
SELECT 
    YEAR(o.OrderDate) AS year,
    MONTH(o.OrderDate) AS month,
    p.ProductName,
    
    SUM(od.Quantity) AS total_quantity

FROM orders o
JOIN order_details od USING (OrderID)
JOIN products p USING (ProductID)

GROUP BY 
    YEAR(o.OrderDate),
    MONTH(o.OrderDate),
    p.ProductName

ORDER BY year, month, total_quantity DESC;

-- Q11
WITH product_rev AS (
    SELECT 
        p.ProductName,
        SUM(od.UnitPrice * od.Quantity) AS revenue
    FROM order_details od
    JOIN products p USING (ProductID)
    GROUP BY p.ProductName
),
avg_val AS (
    SELECT AVG(revenue) AS avg_revenue FROM product_rev
)

SELECT 
    pr.ProductName,
    ROUND(pr.revenue,2) AS revenue,
    ROUND(av.avg_revenue,2) AS avg_revenue,
    
    CASE 
        WHEN pr.revenue > av.avg_revenue * 2 THEN 'High Anomaly'
        WHEN pr.revenue < av.avg_revenue * 0.5 THEN 'Low Anomaly'
        ELSE 'Normal'
    END AS anomaly_flag

FROM product_rev pr
CROSS JOIN avg_val av
ORDER BY revenue DESC;

-- Q12
SELECT 
    s.Country,
    
    COUNT(DISTINCT s.SupplierID) AS total_suppliers,
    
    ROUND(AVG(p.UnitPrice), 2) AS avg_price

FROM suppliers s
JOIN products p USING (SupplierID)

GROUP BY s.Country
ORDER BY avg_price DESC;

-- Q13
SELECT 
    c.CategoryName,
    
    COUNT(DISTINCT p.SupplierID) AS total_suppliers

FROM products p
JOIN categories c USING (CategoryID)

GROUP BY c.CategoryName
ORDER BY total_suppliers DESC;

-- Q14
SELECT 
    s.Country,
    c.CategoryName,
    
    ROUND(AVG(p.UnitPrice), 2) AS avg_price

FROM suppliers s
JOIN products p USING (SupplierID)
JOIN categories c USING (CategoryID)

GROUP BY s.Country, c.CategoryName
ORDER BY s.Country, avg_price DESC;