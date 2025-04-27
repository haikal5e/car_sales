-- ================================
-- 🔍 Database Setup
-- ================================

-- Display the existing databases
SHOW DATABASES;

-- Switch to the classicmodels_new database
USE `classicmodels_new`;

-- Show all tables in the current database
SHOW TABLES;

-- Describe specific tables to understand their structure
DESCRIBE orderdetails;
DESCRIBE orders;
DESCRIBE productlines;
DESCRIBE products;

-- ================================
-- 🔧 STORED PROCEDURES
-- ================================

-- 1. Get Order Details by Order Number
DELIMITER //
CREATE PROCEDURE GetOrderDetails(IN inputOrderNumber INT)
BEGIN
    SELECT 
        o.orderNumber,
        o.orderDate,
        p.productName,
        od.quantityOrdered,
        od.priceEach,
        (od.quantityOrdered * od.priceEach) AS lineTotal
    FROM 
        orders o
    JOIN 
        orderdetails od ON o.orderNumber = od.orderNumber
    JOIN 
        products p ON od.productCode = p.productCode
    WHERE 
        o.orderNumber = inputOrderNumber;
END //
DELIMITER ;

-- Call the stored procedure with an example order number
CALL GetOrderDetails(10165);

-- 2. Get Products Below a Certain Stock Level
DELIMITER //
CREATE PROCEDURE GetLowStockProducts(IN stockThreshold SMALLINT)
BEGIN
    SELECT 
        productCode,
        productName,
        quantityInStock
    FROM 
        products
    WHERE 
        quantityInStock < stockThreshold;
END //
DELIMITER ;

-- Call the stored procedure to see products with low stock
CALL GetLowStockProducts(250);

-- ================================
-- 👁️ VIEWS
-- ================================

-- 3. Orders Revenue View
CREATE VIEW view_orders_revenue AS
SELECT 
    o.orderNumber,
    o.orderDate,
    SUM(od.quantityOrdered * od.priceEach) AS totalOrderRevenue
FROM 
    orders o
JOIN 
    orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY 
    o.orderNumber;

-- 4. Product Inventory View
CREATE VIEW view_product_inventory AS
SELECT 
    productCode,
    productName,
    quantityInStock,
    buyPrice,
    MSRP
FROM 
    products;

-- Show all views
SHOW FULL TABLES WHERE table_type = 'VIEW';

-- Display the contents of the views
SELECT * FROM view_orders_revenue;
SELECT * FROM view_product_inventory;

-- ================================
-- 🔥 TRIGGERS
-- ================================

-- 5. Auto-update product stock after an order is placed
DELIMITER //
CREATE TRIGGER after_orderdetails_insert
AFTER INSERT ON orderdetails
FOR EACH ROW
BEGIN
    UPDATE products
    SET quantityInStock = quantityInStock - NEW.quantityOrdered
    WHERE productCode = NEW.productCode;
END //
DELIMITER ;

-- Check the updated stock levels
SELECT * FROM products;

-- ================================
-- 💡 USEFUL MYSQL QUERIES
-- ================================

-- 6. Join Orders and Order Details
SELECT 
    orders.orderNumber, 
    orders.orderDate, 
    orderdetails.productCode, 
    orderdetails.quantityOrdered, 
    orderdetails.priceEach
FROM orders
JOIN orderdetails ON orders.orderNumber = orderdetails.orderNumber;

-- 7. Join Products with Product Lines
SELECT p.productCode, p.productName, pl.productLine
FROM products p
JOIN productlines pl ON p.productLine = pl.productLine;

-- 8. Total Revenue per Order
SELECT 
    orderdetails.orderNumber, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS totalRevenue
FROM orderdetails
GROUP BY orderdetails.orderNumber;

-- 9. Orders That Have Not Been Shipped
SELECT * FROM orders WHERE shippedDate IS NULL;

-- 10. Orders Within a Specific Date Range
SELECT orderNumber, orderDate, status
FROM orders
WHERE orderDate BETWEEN '2003-01-01' AND '2004-04-26';

-- 11. Basic Product Information
SELECT productCode, productName, quantityInStock, MSRP
FROM products;

-- 12. Product Line Information
SELECT productLine, textDescription
FROM productlines;

-- 13. Top 5 Best-Selling Products
SELECT 
    p.productName,
    SUM(od.quantityOrdered) AS totalSold
FROM 
    products p
JOIN 
    orderdetails od ON p.productCode = od.productCode
GROUP BY 
    p.productName
ORDER BY 
    totalSold DESC
LIMIT 5;

-- 14. Average Quantity Sold of Each Product
SELECT p.productCode, p.productName, AVG(od.quantityOrdered) AS avgQuantity
FROM products p
JOIN orderdetails od ON p.productCode = od.productCode
GROUP BY p.productCode, p.productName;

-- 15. Late Shipped Orders
SELECT 
    orderNumber,
    orderDate,
    requiredDate,
    shippedDate
FROM 
    orders
WHERE 
    shippedDate > requiredDate
ORDER BY 
    shippedDate;

-- 16. Monthly Sales Revenue
SELECT 
    DATE_FORMAT(o.orderDate, '%Y-%m') AS orderMonth,
    SUM(od.quantityOrdered * od.priceEach) AS totalRevenue
FROM 
    orders o
JOIN 
    orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY 
    orderMonth
ORDER BY 
    orderMonth;

-- 17. Product Line Info with Descriptions
SELECT 
    p.productCode,
    p.productName,
    pl.textDescription
FROM 
    products p
LEFT JOIN 
    productlines pl ON p.productLine = pl.productLine
ORDER BY 
    p.productName;

-- 18. Products That Have Never Been Ordered
SELECT 
    p.productCode,
    p.productName
FROM 
    products p
LEFT JOIN 
    orderdetails od ON p.productCode = od.productCode
WHERE 
    od.orderNumber IS NULL;

-- 19. Average Order Value Calculation
SELECT 
    AVG(orderRevenue) AS averageOrderValue
FROM (
    SELECT 
        o.orderNumber,
        SUM(od.quantityOrdered * od.priceEach) AS orderRevenue
    FROM 
        orders o
    JOIN 
        orderdetails od ON o.orderNumber = od.orderNumber
    GROUP BY 
        o.orderNumber
) AS revenue_per_order;

-- 20. Count Orders by Status
SELECT 
    status,
    COUNT(*) AS numberOfOrders
FROM 
    orders
GROUP BY 
    status;

-- 21. Identify Product Line with Most Products
SELECT 
    productLine,
    COUNT(*) AS totalProducts
FROM 
    products
GROUP BY 
    productLine
ORDER BY 
    totalProducts DESC
LIMIT 1;

-- 22. Revenue by Product Line
SELECT 
    pl.productLine,
    SUM(od.quantityOrdered * od.priceEach) AS totalRevenue
FROM 
    productlines pl
JOIN 
    products p ON pl.productLine = p.productLine
JOIN 
    orderdetails od ON p.productCode = od.productCode
GROUP BY 
    pl.productLine
ORDER BY 
    totalRevenue DESC;

-- 23. Products with Low Sales Volume
SELECT 
    p.productName,
    SUM(od.quantityOrdered) AS totalSold
FROM 
    products p
LEFT JOIN 
    orderdetails od ON p.productCode = od.productCode
GROUP BY 
    p.productName
HAVING 
    totalSold < 1500;

-- 24. Year-Over-Year Sales Growth
SELECT 
    YEAR(o.orderDate) AS salesYear,
    SUM(od.quantityOrdered * od.priceEach) AS totalSales
FROM 
    orders o
JOIN 
    orderdetails od ON o.orderNumber = od.orderNumber
GROUP BY 
    salesYear
ORDER BY 
    salesYear;

-- 25. Top Products by Revenue Contribution
SELECT 
    p.productName,
    SUM(od.quantityOrdered * od.priceEach) AS totalProductRevenue
FROM 
    products p
JOIN 
    orderdetails od ON p.productCode = od.productCode
GROUP BY 
    p.productName
ORDER BY 
    totalProductRevenue DESC
LIMIT 10;