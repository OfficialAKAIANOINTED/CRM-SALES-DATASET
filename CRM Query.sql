Create database CRM_Sales_Dataset
select *
from accounts
select *
from products
select *
from sales_pipeline
select *
from sales_teams
select *
from data_dictionary

-- Task 3 DATA CLEANING 
     -- Ensuring Appropriate Names
EXEC sp_rename 'accounts.account', 'Company_Name', 'COLUMN';
EXEC sp_rename 'accounts.sector', 'Industry', 'COLUMN';
EXEC sp_rename 'accounts.Year established', 'Year_Established', 'COLUMN';
EXEC sp_rename 'accounts.revenue', 'Annual_Revenue', 'COLUMN';
EXEC sp_rename 'accounts.employees', 'Number_of_Employees', 'COLUMN';
EXEC sp_rename 'accounts.office_location', 'Headquarters', 'COLUMN';
EXEC sp_rename 'accounts.subsidiary_of', 'Parent_Company', 'COLUMN';  --Renaming of columns Not important 

-- Replacing Null values where necessary 
SELECT COUNT(CASE WHEN close_value IS NULL OR close_date= '' THEN 1 END) AS Null_Count
FROM sales_pipeline;

UPDATE sales_pipeline
SET Close_Value = 0
WHERE Close_Value IS NULL; --Replacing the Null values with 0

UPDATE sales_pipeline
SET account ='Nan'
WHERE account IS NULL; --Replacing the Null values with 0

--Generating Summary statistics 
   --- 1. Total Deals won,lost,prospecting and engaging.
   
   select COUNT(*) as TotalDeals
   from sales_pipeline

      select COUNT(*) as Won_Deals
   from sales_pipeline
   where deal_stage = 'Won'

       select COUNT(*) as Lost_Deals
   from sales_pipeline
   where deal_stage = 'Lost'

       select COUNT(*) as Engaging_Deals
   from sales_pipeline
   where deal_stage = 'Engaging'

       select COUNT(*) as Prospecting_Deals
   from sales_pipeline
   where deal_stage = 'Prospecting'

   ----- 2. Total Revenue 
   select SUM(close_value) AS Total_Revenue
   from sales_pipeline
   
 
   ----- Close values and agent 
   SELECT sales_agent, SUM(close_value) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY sales_agent


   -- 3. Summary of Deal Stages
SELECT Deal_STAGE, 
       COUNT(*) AS NumberOfDeals, 
       MIN(Close_Value) AS MinCloseValue, 
       MAX(Close_Value) AS MaxCloseValue, 
       AVG(Close_Value) AS AvgCloseValue,
       SUM(Close_Value) AS TotalCloseValue
FROM sales_pipeline
GROUP BY Deal_Stage
ORDER BY Deal_Stage;

-- 4. Summary of Sales Agents' Performance

SELECT st.sales_agent, 
       COUNT(*) AS DealsHandled, 
       MIN(sp.close_value) AS MinDealValue, 
       MAX(sp.close_value) AS MaxDealValue, 
       AVG(sp.close_value) AS AvgDealValue, 
       SUM(sp.close_value) AS TotalSales
FROM sales_pipeline sp
LEFT JOIN sales_teams st 
    ON sp.sales_agent = st.sales_agent  -- Ensure the join condition matches the foreign key relation
GROUP BY st.sales_agent
ORDER BY TotalSales desc;



-- 5. Summary of Products Sold
SELECT product,
       COUNT(*) AS NumberOfDeals, 
       MIN(Close_Value) AS MinCloseValue, 
       MAX(Close_Value) AS MaxCloseValue, 
       AVG(Close_Value) AS AvgCloseValue, 
       SUM(Close_Value) AS TotalCloseValue
FROM sales_pipeline 
GROUP BY Product
ORDER BY TotalCloseValue desc;

-- 6. Overall Statistics on Close Values (for entire dataset)
SELECT COUNT(*) AS TotalDeals, 
       MIN(Close_Value) AS MinCloseValue, 
       MAX(close_value) AS MaxCloseValue, 
       AVG(Close_Value) AS AvgCloseValue, 
       SUM(close_value) AS TotalCloseValue
FROM sales_pipeline;

--Merging Relevant Table for analysis 

--Data Types 
ALTER TABLE accounts
ADD year_established_date DATE;

select *
from accounts

ALTER TABLE accounts
DROP COLUMN year_established_date


UPDATE accounts
SET year_established_date = CAST(CONCAT(Year_Established, '-01-01') AS DATE);

--Encooding the deal stage 
  
  SELECT 
    opportunity_id,
    sales_agent,
    close_value,
    close_date,
    deal_stage,
    CASE 
        WHEN deal_stage = 'Won' THEN 1
        WHEN deal_stage = 'Lost' THEN 4
        WHEN deal_stage = 'Prospecting' THEN 2
        WHEN deal_stage = 'Engaging' THEN 3
ELSE 0 
    END AS deal_stage_encoded
FROM sales_pipeline;



 ALTER TABLE sales_pipeline
ADD deal_stage_encoded INT;

UPDATE sales_pipeline
SET deal_stage_encoded = 
    CASE 
        WHEN deal_stage = 'Won' THEN 1
        WHEN deal_stage = 'Lost' THEN 4
        WHEN deal_stage = 'Prospecting' THEN 2
        WHEN deal_stage = 'Engaging' THEN 3
        ELSE 0  
    END;

	select * 
	from sales_pipeline



  --Extracting Quarter and Year from Close date 
SELECT 
    close_date,
    YEAR(close_date) AS Deal_Year,
    DATEPART(QUARTER, close_date) AS Deal_Quarter
FROM sales_pipeline;

ALTER TABLE sales_pipeline
Add Quarter int,
    Year int;

UPDATE sales_pipeline
SET Year = YEAR(close_date),
Quarter = DATEPART(QUARTER, close_date);


UPDATE sales_pipeline
SET Quarter = 0, Year = 0
WHERE Quarter IS NULL OR Year IS NULL;

select * 
from sales_pipeline


--Sales team performance analysis

   -- Number of deals won by sales agent 
SELECT sales_agent, COUNT(*) AS deal_stage_count
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY sales_agent
ORDER BY deal_stage_count DESC;
 

   -- Number of deals generated by sales agent 
   SELECT st.manager, COUNT(*) AS deal_stage_count
FROM sales_pipeline sp
left join sales_teams st
on st.sales_agent = sp.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY st.manager
ORDER BY deal_stage_count DESC;



   -- Revenue Generated by Manager
 SELECT st.manager, SUM(sp.close_value) AS total_revenue
FROM sales_pipeline sp
left join sales_teams st
on st.sales_agent = sp.sales_agent
WHERE deal_stage = 'Won'
GROUP BY manager
ORDER BY total_revenue DESC;


   -- Revenue Generated by Sales Agent 
 SELECT st.sales_agent, SUM(sp.close_value) AS total_revenue
FROM sales_pipeline sp
left join sales_teams st
on st.sales_agent = sp.sales_agent
WHERE deal_stage = 'Won'
GROUP BY st.sales_agent
ORDER BY total_revenue DESC;

-- Win Rate Analysis by sales Agent 
SELECT sales_agent,
    (COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) * 100.0 / COUNT(*)) AS win_rate_percentage
FROM sales_pipeline
GROUP BY sales_agent;

-- Win Rate Analysis by Manager
SELECT 
    st.manager,
    (COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) * 100.0 / COUNT(*)) AS win_rate_percentage
FROM sales_pipeline sp
left join sales_teams st
on st.sales_agent = sp.sales_agent
GROUP BY st.manager


--- TASK 6 PRODUCT WIN RATE ANALYSIS 

-- Win rate by Product 
SELECT product,(COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) * 100.0 / COUNT(*)) AS win_rate_percentage
FROM sales_pipeline
GROUP BY product;

-- Sum of close Value by Product
SELECT  product,SUM(close_value) AS total_revenue
FROM sales_pipeline
GROUP BY product;

-- Win rate by Quater 
SELECT Quarter,(COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) * 100.0 / COUNT(*)) AS win_rate_percentage
FROM  sales_pipeline
GROUP BY  QUARTER
ORDER BY Quarter DESC;


-- TASK 7 Quarter Over Quarter Analysis 
-- Win Rate by Quarter and product 
SELECT  sp.QUARTER,p.product, (COUNT(CASE WHEN deal_stage = 'Won' THEN 1 END) * 100.0 / COUNT(*)) AS win_rate_percentage
FROM sales_pipeline sp
left join products p
on p.product = sp.product
GROUP BY sp.Quarter, p.product
ORDER BY sp.Quarter DESC;

-- Deals Won BY quarter 
SELECT Quarter, COUNT(*) AS deal_stage_Won
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY Quarter
ORDER BY deal_stage_Won DESC;


