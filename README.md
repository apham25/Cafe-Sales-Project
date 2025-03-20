# Café Sales Project

### Dashboard Link : https://app.powerbi.com/groups/me/reports/c8d3e011-b83a-4263-bb05-f6af190969c5/f5f24b3dd82873ed8980?experience=power-bi

## Overview
A café has requested our services in order to improve the operations and financials of their business. A dataset consisting of 10,000 rows of café sales was provided to us; however, there are many NULL values and standardization issues within this dataset. After cleaning the data, we must help stakeholders understand important metrics within this café such as sales performance, customer behavior, and operational efficiency as shown in the dashboard in PowerBI. The objective of this project is to extract insights from the dataset to suggest improvements under the economy of this café to reach the business owners' KPI goal of $7,000 in profit monthly. 

### Steps followed 

- Step 1: Opened source .csv file and standardize columns header by trimming
- Step 2: Created database schema on MySQL and imported .csv data and created table
- Step 3: Created duplicate table with source dataset to clean and standardize data
- Step 4: Cleaned dataset (steps shown in SQL script under "MySQL Café Sales Cleaning")
- Step 5: Explored and analyzed clean dataset to extract actionable insights to be shown on dashboard (steps shown in SQL script under "MySQL Café Sales Data Exploratory Analysis)
- Step 6: Exported final cleaned dataset into .csv file and imported it into PowerBI
- Step 7: Changed column names from "TotalSpent" and "Location" to "Revenue" and "OrderType" to help increase readability for users
- Step 8: Utilized lists to categorize items in either "Beverages" or "Food" and created a new column 
- Step 9: Created separate data table from min date (January 1st, 2023) to max date (December 31st, 2023) referenced from our original dataset to create desired date hierarchies in drilldowns
- Step 10: Implemented slicers for all categorical fields such as Payment Method, Category, Order Type, and Month.
- Step 11: Added three cards to highlight the number of transactions, total revenue, and average revenue per transaction
- Step 12: Added line chart of total revenue by a hierarchy of quarter, month, and weekday to showcase revenue trends
- Step 13: Added stacked bar and column chart of Total Revenue by Category and Item and Total Quantity Sold by Category and Item respectively to analyze the relationship between both variables
- Step 14: Added donut chart and pie chart of Payment Method and Order Type respectively to understand the distribution of each category
- Step 15: Added monthly revenue KPI with a goal of $7,000 in revenue each month indicating if any given month was successful in meeting said goal.
- Step 16: Added table consisting of Item, Price Per Unit, and Revenue to show which Item and Price Per Unit attributed to total revenue the most.
 
 # Dashboard Snapshot (Power BI Desktop)

 
![Image](https://github.com/user-attachments/assets/9ce64935-6841-4d26-9f78-328ce464dc1f)
