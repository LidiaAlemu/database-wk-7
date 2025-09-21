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