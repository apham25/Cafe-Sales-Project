SELECT *
FROM cafesale;

-- First, we will create a duplicate/staging dataset to clean our data with. We want to leave our raw dataset alone

CREATE TABLE staging
LIKE cafesale;

INSERT staging
SELECT * FROM cafesale;

SELECT *
FROM staging; 

# We will be using the staging table from this point forward.

# Steps to Clean Data
-- 1. Identify duplicate rows
-- 2. Standardize data and fix errors
-- 3. Identify and populate null vlaues
-- 4. Delete any rows that cannot be used for analysis

##### 1. Duplicate check #####
SELECT COUNT(transactionID) AS count1, COUNT(DISTINCT transactionID) AS count2
FROM staging;

-- Count and DISTINCT count match, there are no duplicate rows for our primary key

### 2. Standardizing data and fixing errors ###

SELECT *
FROM staging;

SELECT DISTINCT(item) AS distinctitem
FROM staging;

-- Null values are shown as various phrases in all columns. 
-- We will standardize item, quantity, priceperunit, and totalspent into null values.

SELECT *
FROM staging
WHERE item = "Unknown" OR item = "" OR item = "ERROR"; -- 969 values returned

START TRANSACTION; # transaction control statement as precaution
UPDATE staging
SET item = NULL
WHERE item = "Unknown" OR item = "" OR item = "ERROR";
-- ROLLBACK; (in case our update statement is incorrect)

SELECT DISTINCT(item)
FROM staging;

-- Distinct items are correct, our transaction control statement is good to commit
COMMIT; -- 969 values in item field standardized to null value

SELECT quantity
FROM staging
WHERE quantity = "Unknown" OR quantity = "" OR quantity = "ERROR"; -- 479 values returned

START TRANSACTION;
UPDATE staging
SET quantity = NULL
WHERE quantity = "Unknown" OR quantity = "" OR quantity = "ERROR";
-- ROLLBACK;

SELECT DISTINCT(quantity)
FROM staging;
-- Distinct quantities are correct, our transaction control statement is good to commit
COMMIT; -- 479 values in quantity field standardized to null value

SELECT PricePerUnit
FROM staging
WHERE PricePerUnit = "Unknown" OR PricePerUnit = "" OR PricePerUnit = "ERROR"; -- 533 values returned

START TRANSACTION;
UPDATE staging
SET PricePerUnit = NULL
WHERE PricePerUnit = "Unknown" OR PricePerUnit = "" OR PricePerUnit = "ERROR";
-- ROLLBACK;

SELECT DISTINCT(PricePerUnit)
FROM staging;
-- Distinct PricePerUnits are correct, our transaction control statement is good to commit
COMMIT; -- 533 values in PricePerUnit field standardized to null value

SELECT TotalSpent
FROM staging
WHERE TotalSpent = "Unknown" OR TotalSpent = "" OR TotalSpent = "ERROR"; -- 502 values returned

START TRANSACTION;
UPDATE staging
SET TotalSpent = NULL
WHERE TotalSpent = "Unknown" OR TotalSpent = "" OR TotalSpent = "ERROR";
-- ROLLBACK;

SELECT DISTINCT(TotalSpent)
FROM staging;
-- Distinct TotalSpent is correct, our transaction control statement is good to commit
COMMIT; -- 502 values in TotalSpent field standardized to null value
-- In fields item, quantity, PricePerUnit, and TotalSpent, a total of 2,483 values were standardized to null values. 

##### 2. Standardizng Data: Data Type Conversion #####
-- Before we start populating our columns, I want to confirm they are the correct data types

DESCRIBE staging; 
-- Currently, all columns are text types. We need to change our numeric columns into the correct types prior to any calculations

ALTER TABLE staging
MODIFY COLUMN Quantity INT NULL,
MODIFY COLUMN PricePerUnit DECIMAL(10,2) NULL,
MODIFY COLUMN TotalSpent DECIMAL(10,2) NULL;

DESCRIBE staging;

-- Data types look good, we can now begin the imputing process


##### 3. Identifying and imputing NULL Values #####
SELECT PricePerUnit
FROM staging
WHERE PricePerUnit IS NULL; -- 533 null values

-- First, we will want to populate our numerical columns in order to populate our item column.
-- We can do this by referring to the calculation from the TotalSpent column: TotalSpent = Quantity * PricePerUnit
-- PricePerUnit = TotalSpent / Quantity
-- Quantity = TotalSpent/ PricePerUnit

-- Populating PricePerUnit Column

SELECT Item, Quantity, PricePerUnit, ROUND(TotalSpent/Quantity, 2) AS PPU, TotalSpent
FROM staging
WHERE PricePerUnit IS NULL
AND quantity * ROUND(TotalSpent/Quantity,2) = TotalSpent; -- 495 PricePerUnit values that can be calculated and imputed

START TRANSACTION;
UPDATE staging
SET PricePerUnit = ROUND(TotalSpent/Quantity, 2)
WHERE PricePerUnit IS NULL;
-- ROLLBACK;

SELECT *
FROM staging
WHERE PricePerUnit IS NULL; -- 38 rows returned; this is okay since we are missing quantity or totalspent values in each row

SELECT *
FROM staging
WHERE PricePerUnit IS NULL
AND Quantity IS NOT NULL
AND TotalSpent IS NOT NULL; 

-- 0 rows returned, safe to commit
COMMIT;

##### Populating Item Column #####
SELECT Item, Quantity, ROUND(TotalSpent / PricePerUnit, 2) AS popquantity, PricePerUnit, TotalSpent
FROM staging
WHERE Quantity IS NULL
AND TotalSpent = ROUND(TotalSpent / PricePerUnit, 2) * PricePerUnit; -- 441 quantity values that can be calculated and populated

START TRANSACTION;
UPDATE staging
SET quantity = ROUND(TotalSpent / PricePerUnit, 2)
WHERE quantity IS NULL;
-- ROLLBACK;

SELECT *
FROM staging
WHERE quantity IS NULL; -- 38 rows returned; this is okay since we are missing PricePerUnit or totalspent values in each row

SELECT *
FROM staging
WHERE Quantity IS NULL
AND PricePerUnit IS NOT NULL
AND TotalSpent IS NOT NULL; 

-- 0 rows returned, safe to commit
COMMIT;

##### Populating TotalSpent Column #####
SELECT Item, Quantity, PricePerUnit, TotalSpent, Quantity * PricePerUnit AS poptotalspent
FROM staging
WHERE TotalSpent IS NULL
AND PricePerUnit IS NOT NULL
AND Quantity IS NOT NULL; -- 462 TotalSpent values that can be calculated and populated

START TRANSACTION;
UPDATE staging
SET TotalSpent = Quantity * PricePerUnit
WHERE TotalSpent IS NULL;
-- ROLLBACK;

SELECT *
FROM staging
WHERE TotalSpent IS NULL; -- 40 rows returned; this is okay since we are missing PricePerUnit or Quantity values in each row

SELECT *
FROM staging
WHERE TotalSpent IS NULL
AND PricePerUnit IS NOT NULL
AND Quantity IS NOT NULL; 

-- 0 rows returned, safe to commit
COMMIT;


-- Per kaggle dataset creator, items with their respective priceperunit:
-- Coffee = $2, Tea = $1.5, Salad = $5, Cookie = $1
-- Sandwich and Smoothie = $4, Cake and Juice = $3
-- We will populate our null item fields accordingly

##### Populating items w/ unique PricePerUnit (Coffee, Tea, Salad, Cookie) #####
SELECT DISTINCT(item), PricePerUnit
FROM staging
WHERE item IS NOT NULL
ORDER BY PricePerUnit;

START TRANSACTION;
UPDATE staging
SET Item = 
	CASE
    WHEN PricePerUnit = 2.00 THEN 'Coffee'
    WHEN PricePerUnit = 1.50 THEN 'Tea'
    WHEN PricePerUnit = 5.00 THEN 'Salad'
    WHEN PricePerUnit = 1.00 THEN 'Cookie'
    END
WHERE item IS NULL
AND PricePerUnit NOT IN (3.00, 4.00); -- 489 item values populated with respect to their PricePerUnit
-- ROLLBACK;

SELECT DISTINCT(Item), PricePerUnit
FROM staging
WHERE Item IS NULL; 

SELECT item, quantity, priceperunit, totalspent
FROM staging
WHERE item IS NULL
AND PricePerUnit NOT IN (3.00, 4.00);

-- 0 rows returned, safe to commit
COMMIT;

##### Populating items w/ same PricePerUnit (Cake and Juice ($3), Sandwich and Smoothie ($4)) #####
-- Since these items share the same PricePerUnit, we can populate each row by calculating the mode respective to the quantity sold
-- We will start with Cake and Juice

SELECT DISTINCT(item), PricePerUnit, quantity, count(quantity)
FROM staging
WHERE PricePerUnit = 3.00
AND item IS NOT NULL
GROUP BY item, PricePerUnit, quantity
ORDER BY quantity;

SELECT DISTINCT(item), PricePerUnit, quantity, count(quantity)
FROM staging
WHERE PricePerUnit = 3.00
AND item IS NULL
AND quantity IS NOT NULL
GROUP BY item, PricePerUnit, quantity
ORDER BY quantity;
-- 247 item nulls should be populated with their respective mode in quantity

START TRANSACTION;
WITH quantitycount AS
(
SELECT Item, Quantity, COUNT(ITEM) AS count
FROM staging
WHERE PricePerUnit = 3.00
AND item IS NOT NULL
GROUP BY Item, Quantity
ORDER BY quantity
),
modecheck AS
(
SELECT Item, Quantity, count,
RANK() OVER(PARTITION BY quantity ORDER BY count DESC) AS moderank
FROM quantitycount
ORDER BY quantity
)
UPDATE staging AS s
LEFT JOIN modecheck AS m
	ON s.quantity = m.quantity
SET s.item = m.item
WHERE s.item IS NULL
AND PricePerUnit = 3.00
AND moderank = 1;
-- ROLLBACK;

SELECT DISTINCT(item), PricePerUnit
FROM staging
WHERE PricePerUnit = 3.00;

SELECT DISTINCT(item), PricePerUnit, quantity, count(quantity)
FROM staging
WHERE PricePerUnit = 3.00
AND item IS NOT NULL
GROUP BY item, PricePerUnit, quantity
ORDER BY quantity;

SELECT item, PricePerUnit, Quantity, TotalSpent
FROM staging
WHERE item IS NULL
AND PricePerUnit = 3.00;

-- 0 rows returned, safe to commit
COMMIT;

##### Populating items w/ same PricePerUnit (Sandwich and Smoothie ($4)) #####
-- Same process as cake and juice
SELECT item, quantity, PricePerUnit, TotalSpent
FROM staging
WHERE PricePerUnit = 4.00
AND item IS NULL
ORDER BY 2;

SELECT DISTINCT(item), PricePerUnit, quantity, count(quantity)
FROM staging
WHERE PricePerUnit = 4.00
AND item IS NOT NULL
GROUP BY item, PricePerUnit, quantity
ORDER BY quantity;

SELECT DISTINCT(item), PricePerUnit, quantity, count(quantity)
FROM staging
WHERE PricePerUnit = 4.00
AND item IS NULL
GROUP BY item, PricePerUnit, quantity
ORDER BY quantity;

-- 227 item nulls should be populated with their respective mode in quantity

START TRANSACTION;
WITH quantitycount2 AS
(
SELECT Item, Quantity, COUNT(ITEM) AS count
FROM staging
WHERE PricePerUnit = 4.00
AND item IS NOT NULL
GROUP BY Item, Quantity
ORDER BY quantity
),
modecheck2 AS
(
SELECT Item, Quantity, count,
RANK() OVER(PARTITION BY quantity ORDER BY count DESC) AS moderank
FROM quantitycount2
ORDER BY quantity
)
UPDATE staging AS s
LEFT JOIN modecheck2 AS m
	ON s.quantity = m.quantity
SET s.item = m.item
WHERE s.item IS NULL
AND PricePerUnit = 4.00
AND moderank = 1;
-- ROLLBACK;

SELECT DISTINCT(item), PricePerUnit
FROM staging
WHERE PricePerUnit = 4.00;

SELECT DISTINCT(item), PricePerUnit, quantity, count(quantity)
FROM staging
WHERE PricePerUnit = 4.00
AND item IS NOT NULL
GROUP BY item, PricePerUnit, quantity
ORDER BY quantity;

SELECT item, PricePerUnit, Quantity, TotalSpent
FROM staging
WHERE item IS NULL
AND PricePerUnit = 4.00;

-- 0 rows returned, safe to commit
COMMIT;


-- item, quantity, priceperunit, and totalspent have been mostly been imputed
-- however, there are some rows that were unsuccessful due to two variables missing from our equation

SELECT *
FROM staging
WHERE PricePerUnit IS NULL
AND Quantity IS NULL; -- 18 rows where PricePerUnit and Quantity are both null

SELECT *
FROM staging
WHERE PricePerUnit IS NULL
AND TotalSpent IS NULL; -- 20 rows where PricePerUnit and TotalSpent are both null

SELECT *
FROM staging
WHERE Quantity IS NULL
AND TotalSpent IS NULL; -- 20 rows where Quantity and Total Spent are both null

-- 58 rows where two variables in our equation are null
-- we will decide what to do with these null values when we are complete with the standardization of our data set

##### Populating PaymentMethod, Location, and TransactionDate #####
-- Null values are various phrases in these next few columns
-- we will start by standardizing these values

SELECT DISTINCT(PaymentMethod)
FROM staging;

-- null values are various phrases similar to previous columns
START TRANSACTION;
UPDATE staging
SET PaymentMethod = NULL
WHERE PaymentMethod = 'UNKNOWN'
OR PaymentMethod = 'ERROR'
OR PaymentMethod = ''; -- 3178 values changed to null values
-- ROLLBACK

SELECT DISTINCT(PaymentMethod)
FROM staging;

-- Distinct values are correct, safe to commit
COMMIT;

SELECT DISTINCT(Location)
FROM staging;

START TRANSACTION;
UPDATE staging
SET Location = NULL
WHERE Location = 'UNKNOWN'
OR Location = 'ERROR'
OR Location = ''; -- 3961 values changed to null values
#ROLLBACK

SELECT DISTINCT(Location)
FROM staging;

-- Distinct values are correct, safe to commit
COMMIT;

SELECT DISTINCT(TransactionDate)
FROM staging
ORDER BY 1 DESC;

START TRANSACTION;
UPDATE staging
SET TransactionDate = NULL
WHERE TransactionDate = 'UNKNOWN'
OR TransactionDate = 'ERROR'
OR TransactionDate = ''; -- 460 values changed to null values
-- ROLLBACK

SELECT DISTINCT(TransactionDate)
FROM staging
ORDER BY 1 DESC;

-- Distinct values are correct, safe to commit
COMMIT;

##### Imputing PaymentMethod column #####
SELECT PaymentMethod, COUNT(*) AS paymentcount
FROM staging
GROUP BY PaymentMethod; -- 3178 null values that need to be imputed

SELECT Item, TotalSpent, PaymentMethod, COUNT(TotalSpent) AS totalspentcount
FROM staging
GROUP BY Item, TotalSpent, PaymentMethod
ORDER BY 2;

-- previously, we imputed our data by the mode of our item with partitioned by quantity
-- however, with paymentmethod, I believe this will not be optimal as it will definitely skew the data
-- the distribution with payment method is fairly even as shown above
-- we will keep this distribution uniform by imputing each category at random

DROP TABLE IF EXISTS randpayment;
CREATE TEMPORARY TABLE randpayment AS
SELECT PaymentMethod
FROM staging
WHERE PaymentMethod IS NOT NULL
ORDER BY RAND(); -- we create a temp table since MySQL cannot update succesfully w/ a subquery

START TRANSACTION;
UPDATE staging
SET PaymentMethod = (
    SELECT PaymentMethod
    FROM randpayment
    WHERE PaymentMethod IS NOT NULL
    ORDER BY RAND()
    LIMIT 1
)
WHERE PaymentMethod IS NULL;
-- ROLLBACK;

SELECT PaymentMethod, COUNT(*) AS count
FROM staging
GROUP BY PaymentMethod; -- distribution is still fairly evenly distributed

SELECT *
FROM staging
WHERE PaymentMethod IS NULL;

-- 0 rows returned, safe to commit
COMMIT;

##### Imputing Location column #####
-- same process as the PaymentMethod column; imputing mode partitioned by any given column will skew results
-- distribution is very even in location column

SELECT location, COUNT(*) AS count
FROM staging
GROUP BY location;

DROP TABLE IF EXISTS randlocation;
CREATE TEMPORARY TABLE randlocation AS
SELECT Location
FROM staging
WHERE Location IS NOT NULL
ORDER BY RAND(); 

SELECT Location, COUNT(*) AS rancount
FROM randlocation
GROUP BY 1; 

START TRANSACTION;
UPDATE staging
SET Location = (
    SELECT location
    FROM randlocation
    ORDER BY RAND()
    LIMIT 1
)
WHERE Location IS NULL;
-- ROLLBACK;

SELECT Location, COUNT(*) AS count
FROM staging
GROUP BY Location; -- distribution is still fairly evenly distributed

SELECT *
FROM staging
WHERE Location IS NULL;

-- 0 rows returned, safe to commit
COMMIT;

##### Imputing Transaction Date #####

-- first, we need to change our field type to DATE
DESCRIBE staging;

ALTER TABLE staging
MODIFY COLUMN TransactionDate DATE;

-- format is currently in MM/DD/YYYY, needs to be in YYYY-MM-DD to modify data type

SELECT TransactionDate
FROM staging
WHERE STR_TO_DATE(TransactionDate, '%m/%d/%Y') IS NULL; -- all dates are formatted correctly

START TRANSACTION;
UPDATE staging
SET TransactionDate = STR_TO_DATE(TransactionDate, '%m/%d/%Y');
-- ROLLBACK;

SELECT TransactionDate
FROM staging;

-- values successfully converted into correct format, safe to commit
COMMIT;

ALTER TABLE staging
MODIFY COLUMN TransactionDate DATE; -- query now runs successfully

SELECT *
FROM staging;

-- TransactionDate does not seem to follow chronological order.
-- To populate our null date values, we want to order by TransactionID to see if our data is in sequential order

SELECT *
FROM staging
ORDER BY TransactionID; -- Ordering looks strange since there is text in each values

SELECT TransactionID, LENGTH(TransactionID) AS lengthcheck
FROM staging
WHERE LENGTH(TransactionID) != 11;

SELECT *, REPLACE(TransactionID, 'TXN_', '') AS TID
FROM staging;

START TRANSACTION;
UPDATE staging
SET TransactionID = REPLACE(TransactionID, 'TXN_', '');

SELECT *
FROM staging
WHERE TransactionID LIKE '%TXN%';

-- 0 rows returned, safe to commit
COMMIT;

SELECT *
FROM staging
ORDER BY TransactionID;

-- TransactionID is not sequential; our TransactionDate is still not in chronological order
-- This dataset seems to be random.
-- Since our dataset's null values seem to be missing at random, we will opt to delete rows where TransactionDate is null

##### 4. Deleting null values #####

WITH counts AS
(
SELECT (SELECT COUNT(*)
		FROM staging
		WHERE TransactionDate IS NULL) AS nullcountdate,
COUNT(*) AS countall
FROM staging
)
SELECT ROUND(nullcountdate/countall * 100, 2) AS percentnull -- TransactionDate null values consist of 4.6% of the dataset
FROM counts; 

START TRANSACTION;
DELETE FROM staging
WHERE TransactionDate IS NULL;
-- ROLLBACK;

SELECT *
FROM staging
WHERE TransactionDate IS NULL;

-- 0 rows returned, safe to commit
COMMIT;


-- We will also delete any rows where at least two variables of our equation Quantity * PricePerUnit = TotalSpent are null
START TRANSACTION;
DELETE FROM staging
WHERE item IS NULL
OR quantity IS NULL
OR PricePerUnit IS NULL
OR TotalSpent IS NULL; -- 55 rows where at least 2 column values are null
ROLLBACK;

SELECT *
FROM staging
WHERE item IS NULL
OR quantity IS NULL
OR PricePerUnit IS NULL
OR TotalSpent IS NULL;

-- 0 rows returned; safe to commit
COMMIT;

##### Null value Check #####
SELECT *
FROM staging
WHERE TransactionID IS NULL
OR item IS NULL OR quantity IS NULL
OR PricePerUnit IS NULL OR TotalSpent IS NULL
OR PaymentMethod IS NULL OR Location IS NULL
OR TransactionDate IS NULL; 

-- 0 null values in our dataset. Our dataset is now clean! 

SELECT *
FROM staging;


 








