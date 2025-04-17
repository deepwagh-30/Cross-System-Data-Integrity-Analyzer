use [Crosstem]
go

-- 1. Basic Exploration and Aggregation 

-- total gross sales
SELECT SUM("Gross_Sales") AS TotalGrossSales
FROM [dbo].[orders_and_shipments];

-- total profit
SELECT SUM(Profit) AS TotalProfit
FROM [dbo].[orders_and_shipments] 


-- Sales and Profit by Product Department:
SELECT "Product_Department",
       SUM("Gross_Sales") AS TotalSales,
       SUM(Profit) AS TotalProfit
FROM [dbo].[orders_and_shipments]
GROUP BY "Product_Department" 
ORDER BY TotalSales DESC;


-- Sales and Profit by Product Category:
SELECT "Product_Category",
       SUM("Gross_Sales") AS TotalSales,
       SUM(Profit) AS TotalProfit
FROM [dbo].[orders_and_shipments]
GROUP BY "Product_Category"
ORDER BY TotalSales DESC;



-- Top Selling Products
SELECT TOP 10 
       [Product_Name],
       SUM([Order_Quantity]) AS TotalQuantitySold,
       SUM([Gross_Sales]) AS TotalSales
FROM [dbo].[orders_and_shipments]
GROUP BY [Product_Name]
ORDER BY TotalQuantitySold DESC;




-- Profitability by Product
SELECT TOP 10 
       [Product_Name] AS ProductName,
       SUM(Profit) AS TotalProfit,
       SUM([Gross_Sales]) AS TotalSales
FROM [dbo].[orders_and_shipments]
GROUP BY [Product_Name]
ORDER BY TotalProfit DESC;



-- Sales Trends Over Time (Monthly):
SELECT "Order_YearMonth",
       SUM("Gross_Sales") AS MonthlySales
FROM [dbo].[orders_and_shipments]
GROUP BY "Order_YearMonth"
ORDER BY "Order_YearMonth";



-- Sales Trends Over Time (Yearly):
SELECT "Order_Year",
       SUM("Gross_Sales") AS YearlySales
FROM [dbo].[orders_and_shipments]
GROUP BY "Order_Year"
ORDER BY "Order_Year";



-- Sales by Customer Market:
SELECT "Customer_Market",
       SUM("Gross_Sales") AS TotalSales
FROM [dbo].[orders_and_shipments]
GROUP BY "Customer_Market"
ORDER BY TotalSales DESC;



--Sales by Customer Region:
SELECT "Customer_Region",
       SUM("Gross_Sales") AS TotalSales
FROM [dbo].[orders_and_shipments]
GROUP BY "Customer_Region"
ORDER BY TotalSales DESC;



-- Sales by Customer Country:
SELECT "Customer_Country",
       SUM("Gross_Sales") AS TotalSales
FROM [dbo].[orders_and_shipments]
GROUP BY "Customer_Country"
ORDER BY TotalSales DESC;


-- Sales by Warehouse Country:
SELECT "Warehouse_Country",
       SUM("Gross_Sales") AS TotalSales
FROM [dbo].[orders_and_shipments]
GROUP BY "Warehouse_Country"
ORDER BY TotalSales DESC;




-- Impact of Discount
SELECT
    CASE
        WHEN "Discount" > 0 THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS DiscountCategory,
    COUNT(*) AS NumberOfOrders,
    SUM("Gross_Sales") AS TotalGrossSales,
    SUM(Profit) AS TotalProfit
FROM [dbo].[orders_and_shipments]
GROUP BY DiscountCategory;




-- Average Shipment Days:
SELECT AVG("Shipment_Days_Scheduled") AS AverageShipmentDays
FROM [dbo].[orders_and_shipments]
WHERE "Shipment_Days_Scheduled" IS NOT NULL;




-- Sales by Shipment Mode:
SELECT "Shipment_Mode",
       SUM("Gross_Sales") AS TotalSales
FROM [dbo].[orders_and_shipments]
GROUP BY "Shipment_Mode"
ORDER BY TotalSales DESC;


-- 2. Time-Based Analysis

-- Month-over-Month Sales Growth
WITH MonthlySales AS (
    SELECT [Order_YearMonth],
           SUM([Gross_Sales]) AS MonthlySales
    FROM [dbo].[orders_and_shipments]
    GROUP BY [Order_YearMonth]
),
LaggedSales AS (
    SELECT [Order_YearMonth],
           MonthlySales,
           LAG(MonthlySales, 1, 0) OVER (ORDER BY [Order_YearMonth]) AS PreviousMonthSales
    FROM MonthlySales
)
SELECT [Order_YearMonth],
       MonthlySales,
       PreviousMonthSales,
       CASE 
           WHEN PreviousMonthSales = 0 THEN NULL
           ELSE (MonthlySales - PreviousMonthSales) * 100.0 / PreviousMonthSales
       END AS MonthlyGrowthPercentage
FROM LaggedSales
ORDER BY [Order_YearMonth];



-- Year-over-Year Sales Growth:

WITH YearlySales AS (
    SELECT [Order_Year],
           SUM([Gross_Sales]) AS YearlySales
    FROM [dbo].[orders_and_shipments]
    GROUP BY [Order_Year]
),
LaggedSales AS (
    SELECT [Order_Year],
           YearlySales,
           LAG(YearlySales, 1, 0) OVER (ORDER BY [Order_Year]) AS PreviousYearSales
    FROM YearlySales
)
SELECT [Order_Year],
       YearlySales,
       PreviousYearSales,
       CASE 
           WHEN PreviousYearSales = 0 THEN NULL
           ELSE (YearlySales - PreviousYearSales) * 100.0 / PreviousYearSales
       END AS YearlyGrowthPercentage
FROM LaggedSales
ORDER BY [Order_Year];


-- 3. Customer Analysis:
--Top Customers by Purchase Amount:

SELECT TOP 10 
       [Customer_ID],
       SUM([Gross_Sales]) AS TotalPurchaseAmount,
       COUNT(DISTINCT [Order_ID]) AS NumberOfOrders
FROM [dbo].[orders_and_shipments]
GROUP BY [Customer_ID]
ORDER BY TotalPurchaseAmount DESC;



-- Customer Retention (Simple - based on multiple orders):
SELECT [Customer_ID],
       COUNT(DISTINCT [Order_YearMonth]) AS MonthsOrdered
FROM [dbo].[orders_and_shipments]
GROUP BY [Customer_ID]
HAVING COUNT(DISTINCT [Order_YearMonth]) > 1
ORDER BY MonthsOrdered DESC;




-- Queries Joining with Inventory Table:
-- Calculate Total Inventory Value:

SELECT SUM(i."Warehouse_Inventory" * i."Inventory_Cost_Per_Unit") AS TotalInventoryValue
FROM [dbo].[inventory] i;

-- Inventory Value by Product:
SELECT i."Product_Name",
       SUM(i."Warehouse_Inventory" * i."Inventory_Cost_Per_Unit") AS TotalProductInventoryValue
FROM [dbo].[inventory] i
GROUP BY i."Product_Name"
ORDER BY TotalProductInventoryValue DESC;

-- Sales and Inventory Value by Product (Potential for Stockout/Overstock Analysis):

SELECT
    o."Product_Name",
    SUM(o."Order_Quantity") AS TotalQuantitySold,
    MAX(i."Warehouse_Inventory") AS LatestInventory, -- Assuming you want the latest inventory for the period
    SUM(o."Gross_Sales") AS TotalSales
FROM [dbo].[orders_and_shipments] o
JOIN [dbo].[inventory] i ON o."Product_Name" = i."Product_Name" AND o."Order_YearMonth" = i."Year_Month"
GROUP BY o."Product_Name"
ORDER BY TotalSales DESC;

--Inventory Cost Per Unit

SELECT
    o."Product_Name",
    SUM(o."Gross_Sales") AS TotalSales,
    SUM(o."Order_Quantity" * i."Inventory_Cost_Per_Unit") AS EstimatedCOGS,
    SUM(o."Gross_Sales") - SUM(o."Order_Quantity" * i."Inventory_Cost_Per_Unit") AS EstimatedGrossProfit
FROM [dbo].[orders_and_shipments] o
JOIN [dbo].[inventory] i ON o."Product_Name" = i."Product_Name" AND o."Order_YearMonth" = i."Year_Month"
GROUP BY o."Product_Name"
ORDER BY EstimatedGrossProfit DESC;

-- Queries Joining with Fulfillment Table:

-- Average Fulfillment Time by Product:

SELECT
    o."Product_Name",
    AVG(f."Warehouse_Order_Fulfillment (days)") AS AverageFulfillmentDays
FROM [dbo].[orders_and_shipments] o
JOIN [dbo].[fulfillment] f ON o."Product_Name" = f."Product_Name"
GROUP BY o."Product_Name"
ORDER BY AverageFulfillmentDays DESC;

-- Relationship Between Fulfillment Time and Sales (Potentially):

SELECT
    f."_Warehouse_Order_Fulfillment_(days)",
    COUNT(*) AS NumberOfOrders,
    AVG(o."Gross_Sales") AS AverageOrderValue
FROM [dbo].[orders_and_shipments] o
JOIN [dbo].[fulfillment] f ON o."Product_Name" = f."Product_Name"
GROUP BY f."_Warehouse_Order_Fulfillment_(days)"
ORDER BY f."_Warehouse_Order_Fulfillment_(days)";

