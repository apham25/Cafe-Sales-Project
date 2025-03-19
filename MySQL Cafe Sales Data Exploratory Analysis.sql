### Data Exploratory Analysis: Cafe Sales 2023 ###

SELECT *
FROM staging;

# 1. Top 5 selling items based on quantity
SELECT Item, COUNT(*) AS quantitycount, 
DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM staging
GROUP BY Item
ORDER BY quantitycount DESC
LIMIT 5;
-- If stakeholder prioritizes quantity sold for their business, we should push these 5 items

# 2. Top 5 selling items based on revenue
SELECT Item, SUM(TotalSpent) AS TotalRevenue,
DENSE_RANK() OVER(ORDER BY SUM(TotalSpent) DESC) AS ranking
FROM staging
GROUP BY Item
ORDER BY TotalRevenue DESC
LIMIT 5;
-- If stakeholder prioritizes revenue sold for their business, we should push these 5 items.

# 3. What are the top 5 months in terms of revenue?
WITH monthrevenue AS
(
SELECT MONTH(TransactionDate) AS MonthNo, MONTHNAME(TransactionDate) AS MonthName,
SUM(TotalSpent) AS Revenue
FROM staging
GROUP BY MonthNo, MonthName
ORDER BY MonthNo)
SELECT MonthName, Revenue, DENSE_RANK() OVER(ORDER BY Revenue DESC) AS ranking
FROM monthrevenue
LIMIT 5;
-- These top 5 months appear to be our peak business times
-- However, the difference in our revenue month-to-month are marginal
-- This tells me our income is very static. Stakeholders will be advised to look at their business model

# 4. What is the total revenue generated over time?
WITH monthlyrevenue AS
(
SELECT MONTH(TransactionDate) AS MonthNo, MONTHNAME(TransactionDate) AS MonthName,
SUM(TotalSpent) AS Revenue
FROM staging
GROUP BY MonthNo, MonthName
ORDER BY MonthNo
)
SELECT MonthName, Revenue, SUM(Revenue) OVER(ORDER BY MonthNo) AS RunningRevenue
FROM monthlyrevenue;
-- This shows us how static our revenue is on a month-by-month basis
-- There seems to be no seasonality or trends in the year 2023
-- Marginal gains/losses per month are a few hundred dollars
-- Stakeholders definitely need to look at business model as a whole

# 5. Which items contribute most to total revenue?

SELECT SUM(TotalSpent) AS TotalRevenue
FROM staging;

WITH RevenuePercentage AS
(
SELECT Item, PricePerUnit, SUM(Quantity) AS TotalQuantitySold, SUM(TotalSpent) AS Revenue, 
	(SELECT SUM(TotalSpent) FROM staging) AS TotalRevenue
FROM staging
GROUP BY Item, PricePerUnit
)
SELECT *, ROUND((Revenue / TotalRevenue) * 100, 2) AS PercentOfTotal
FROM RevenuePercentage
ORDER BY PercentOfTotal DESC;
-- As price per unit increases, percent of revenue per item towards total revenue increases
-- This shows that the items with the highest price per units give us the most revenue
-- Althrough there is a correlation between percent of revenue per item and price per unit, 
-- Total quantity sold remains static; marginal increases/decreases are only a couple hundreds units
-- This should not be the case; prices w/ lower PPUs should be sold at a much higher rate than those with higher PPUs
-- Recommend stake holders to analyze their business model

# 6. What percentage of transactions use cash, credit card, or digital wallets?
WITH MethodPercentage AS
(
SELECT PaymentMethod, COUNT(*) AS MethodCount,
	(SELECT COUNT(*) FROM staging) AS TotalTransactions
FROM staging
GROUP BY PaymentMethod
)
SELECT *, ROUND((MethodCount / TotalTransactions * 100), 2) AS PercentOfTotal
FROM MethodPercentage;
-- Percentages of transactions for each payment method are equally distributed
-- As such, we should not look into removing a payment method

# 7. Are certain payment methods more popular for specific items or locations?
WITH ItemMethodPCT AS
(
SELECT Item, PaymentMethod, COUNT(*) AS Count,
	(SELECT COUNT(*) FROM staging) AS TotalTransactions
FROM staging
GROUP BY Item, PaymentMethod
ORDER BY count DESC
)
SELECT *, ROUND((Count / TotalTransactions * 100), 2) AS PercentOfTotal
FROM ItemMethodPCT
ORDER BY Item;
-- Percentages of transactions for each item and payment method are relatively equal in distribution
-- Marginal increases/decreases are only tenths of percents
-- Certain payment methods are not more popular for specific items

WITH LocationMethodPCT AS
(
SELECT Location, PaymentMethod, COUNT(*) AS Count,
	(SELECT COUNT(*) FROM staging) AS TotalTransactions
FROM staging
GROUP BY Location, PaymentMethod
ORDER BY count DESC
)
SELECT *, ROUND((Count / TotalTransactions * 100), 2) AS PercentOfTotal
FROM LocationMethodPCT
ORDER BY Location;
-- Percentages of transactions for each location and payment method are relatively equal in distribution
-- Marginal increases/decreases are only tenths of percents
-- Certain payment methods are not more popular for specific locations

# 8. How do sales differ between Takeaway and In-store Purchases?
SELECT Location, COUNT(*) AS Count
FROM staging
GROUP BY Location;
-- Distribution between takeaway and in-store purchases are equal in distribution
-- We should not recommend to stakeholders to focus on one location over the other

# 9. Do certain items sell better in one location type versus the other?

WITH QuantitySold AS
(
SELECT item, location, SUM(Quantity) AS TotalQuantitySold
FROM staging
GROUP BY Item, Location
ORDER BY Location, TotalQuantitySold
)
SELECT t1.item, t1.location, t1.TotalQuantitySold, 
t2.location, t2.TotalQuantitySold, ABS(t1.TotalQuantitySold - t2.TotalQuantitySold) AS Difference
FROM QuantitySold AS t1
JOIN QuantitySold AS t2
	ON t1.item = t2.item
WHERE t1.location = 'In-store'
AND t2.location = 'Takeaway'
ORDER BY difference DESC;
-- Certain items do sell better in one location versus the other marginally
-- However, the difference is not large enough to warrant specific targeting in business model towards item and location
-- We will now implement our findings to PowerBI and create a dashboard!


