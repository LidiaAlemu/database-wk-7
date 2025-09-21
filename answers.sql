-- Question 1: Achieving 1NF (First Normal Form)
-- Transform ProductDetail table to 1NF by splitting the Products column

-- First, create a temporary table to work with the data
CREATE TEMPORARY TABLE temp_product_detail AS
SELECT OrderID, CustomerName, Products
FROM (
    SELECT 101 AS OrderID, 'John Doe' AS CustomerName, 'Laptop, Mouse' AS Products
    UNION SELECT 102, 'Jane Smith', 'Tablet, Keyboard, Mouse'
    UNION SELECT 103, 'Emily Clark', 'Phone'
) AS sample_data;

-- Method 1: Using a recursive CTE to split the Products column (for MySQL 8.0+)
WITH RECURSIVE split_products AS (
    SELECT 
        OrderID,
        CustomerName,
        TRIM(SUBSTRING_INDEX(Products, ',', 1)) AS Product,
        CASE 
            WHEN LOCATE(',', Products) > 0 
            THEN TRIM(SUBSTRING(Products, LOCATE(',', Products) + 1))
            ELSE ''
        END AS remaining_products
    FROM temp_product_detail
    
    UNION ALL
    
    SELECT 
        OrderID,
        CustomerName,
        TRIM(SUBSTRING_INDEX(remaining_products, ',', 1)) AS Product,
        CASE 
            WHEN LOCATE(',', remaining_products) > 0 
            THEN TRIM(SUBSTRING(remaining_products, LOCATE(',', remaining_products) + 1))
            ELSE ''
        END AS remaining_products
    FROM split_products
    WHERE remaining_products != ''
)

-- Create the 1NF table
CREATE TABLE ProductDetail_1NF AS
SELECT 
    OrderID,
    CustomerName,
    Product
FROM split_products
WHERE Product != ''
ORDER BY OrderID, Product;

-- Display the 1NF result
SELECT '1NF Transformation Result:' AS Result;
SELECT * FROM ProductDetail_1NF ORDER BY OrderID, Product;

-- Method 2: Alternative approach using a numbers table (for older MySQL versions)
CREATE TABLE numbers (n INT);
INSERT INTO numbers VALUES (1), (2), (3), (4), (5);

CREATE TABLE ProductDetail_1NF_Alt AS
SELECT 
    p.OrderID,
    p.CustomerName,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Products, ',', n.n), ',', -1)) AS Product
FROM temp_product_detail p
JOIN numbers n
    ON CHAR_LENGTH(p.Products) - CHAR_LENGTH(REPLACE(p.Products, ',', '')) >= n.n - 1
ORDER BY p.OrderID, n.n;

-- Display alternative 1NF result
SELECT 'Alternative 1NF Transformation Result:' AS Result;
SELECT * FROM ProductDetail_1NF_Alt ORDER BY OrderID, Product;

-- Question 2: Achieving 2NF (Second Normal Form)
-- Transform OrderDetails table to 2NF by removing partial dependencies

-- First, create a temporary table with the sample data
CREATE TEMPORARY TABLE temp_order_details AS
SELECT OrderID, CustomerName, Product, Quantity
FROM (
    SELECT 101 AS OrderID, 'John Doe' AS CustomerName, 'Laptop' AS Product, 2 AS Quantity
    UNION SELECT 101, 'John Doe', 'Mouse', 1
    UNION SELECT 102, 'Jane Smith', 'Tablet', 3
    UNION SELECT 102, 'Jane Smith', 'Keyboard', 1
    UNION SELECT 102, 'Jane Smith', 'Mouse', 2
    UNION SELECT 103, 'Emily Clark', 'Phone', 1
) AS sample_data;

-- Step 1: Create Orders table (removes partial dependency of CustomerName on OrderID)
CREATE TABLE Orders_2NF AS
SELECT DISTINCT 
    OrderID,
    CustomerName
FROM temp_order_details
ORDER BY OrderID;

-- Step 2: Create OrderItems table (contains only attributes that depend on the full primary key)
CREATE TABLE OrderItems_2NF AS
SELECT 
    OrderID,
    Product,
    Quantity
FROM temp_order_details
ORDER BY OrderID, Product;

-- Add primary key and foreign key constraints
ALTER TABLE Orders_2NF ADD PRIMARY KEY (OrderID);
ALTER TABLE OrderItems_2NF ADD PRIMARY KEY (OrderID, Product);
ALTER TABLE OrderItems_2NF ADD FOREIGN KEY (OrderID) REFERENCES Orders_2NF(OrderID);

-- Display the 2NF results
SELECT '2NF Transformation - Orders Table:' AS Result;
SELECT * FROM Orders_2NF ORDER BY OrderID;

SELECT '2NF Transformation - OrderItems Table:' AS Result;
SELECT * FROM OrderItems_2NF ORDER BY OrderID, Product;

-- Documentation and Explanation
/*
Normalization Process Summary:

1NF Transformation:
- Split comma-separated Products column into individual rows
- Each row now represents a single product for an order
- Eliminated multi-valued attributes

2NF Transformation:
- Created separate Orders table to store CustomerName (depends only on OrderID)
- Created OrderItems table to store Product and Quantity (depend on full composite key)
- Added proper primary key and foreign key constraints
- Eliminated partial dependencies

Benefits:
- Reduced data redundancy
- Improved data integrity
- Better query performance
- Easier maintenance and updates
*/