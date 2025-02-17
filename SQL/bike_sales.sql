-- 1. Modify column data types for consistency and precision
ALTER TABLE `bike sales data`
MODIFY COLUMN Unit_Cost DECIMAL(10,2),
MODIFY COLUMN Unit_Price DECIMAL(10,2),
MODIFY COLUMN Profit DECIMAL(10,2),
MODIFY COLUMN Cost DECIMAL(10,2),
MODIFY COLUMN Revenue DECIMAL(10,2),
MODIFY COLUMN `Date` DATE;

-- 2. Rename the Sales_Order column for consistency and ease of use
ALTER TABLE `bike sales data`
RENAME COLUMN `Sales_Order #` TO Sales_Order;

-- 3. Fix misspelled values and trim whitespace in a single update
UPDATE `bike sales data`
SET 
    Month = CASE WHEN Month = 'Decmber' THEN 'December' ELSE Month END,
    Country = TRIM(Country);

-- 4. Remove duplicates while keeping the earliest record
WITH Dedup AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY Sales_Order, Customer_Age, Product_Description, `Date`, Order_Quantity, Unit_Cost, Unit_Price, Profit, Cost, Revenue
        ORDER BY Sales_Order ASC
    ) AS row_num
    FROM `bike sales data`
)
DELETE FROM `bike sales data`
WHERE Sales_Order IN (SELECT Sales_Order FROM Dedup WHERE row_num > 1);

-- 5. Handle missing values
UPDATE `bike sales data`
SET 
    Age_Group = CASE 
        WHEN Age_Group IS NULL THEN 'Adults(35-64)' 
        ELSE Age_Group 
    END,
    Product_Description = COALESCE(Product_Description, 'Mountain-200 Black, 46');

-- 6. Optimize cost and revenue calculations
UPDATE `bike sales data`
SET 
    Unit_Cost = CASE WHEN Unit_Cost = 0 AND Cost = 0 THEN (Revenue - Profit) / NULLIF(Order_Quantity, 0) ELSE Unit_Cost END,
    Cost = CASE WHEN Cost = 0 THEN Revenue - Profit ELSE Cost END,
    Revenue = CASE WHEN Revenue = 0 THEN Cost + Profit ELSE Revenue END,
    Unit_Price = CASE WHEN Unit_Price = 0 THEN Revenue / NULLIF(Order_Quantity, 0) ELSE Unit_Price END;

-- 7. Create an index to optimize searches
CREATE INDEX idx_revenue ON `bike sales data` (Revenue);
CREATE INDEX idx_sales ON `bike sales data` (Sales_Order);

-- 8. Retrieve top 10 products by revenue
WITH ProductRevenue AS (
    SELECT Product_Description, SUM(Order_Quantity) AS Total_Quantity, SUM(Revenue) AS Total_Revenue
    FROM `bike sales data`
    GROUP BY Product_Description
)
SELECT * FROM ProductRevenue
ORDER BY Total_Revenue DESC
LIMIT 10;

-- 9. Analyze total revenue by age group and gender with a filter
SELECT Age_Group, Customer_Gender, SUM(Revenue) AS Total_Revenue
FROM `bike sales data`
GROUP BY Age_Group, Customer_Gender
HAVING SUM(Revenue) > 1000
ORDER BY Total_Revenue DESC;

-- 10. Find least profitable products efficiently
SELECT Product_Description, SUM(Cost) AS Total_Cost, SUM(Revenue) AS Total_Revenue, SUM(Profit) AS Total_Profit
FROM `bike sales data`
GROUP BY Product_Description
ORDER BY Total_Profit ASC
LIMIT 5;

-- 11. Sales analysis by country and state
SELECT Country, State, SUM(Revenue) AS Total_Revenue, SUM(Profit) AS Total_Profit, SUM(Order_Quantity) AS Total_Orders, COUNT(DISTINCT Sales_Order) AS Total_Sales_Orders
FROM `bike sales data`
GROUP BY Country, State
HAVING SUM(Revenue) > 10000
ORDER BY Total_Revenue DESC;

-- 12. Identify highest revenue day
SELECT `Date`, SUM(Revenue) AS Total_Revenue
FROM `bike sales data`
GROUP BY `Date`
ORDER BY Total_Revenue DESC
LIMIT 1;

