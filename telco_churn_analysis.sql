-- =========================================================
-- TELCO CUSTOMER CHURN ANALYSIS
-- MySQL analysis of customer churn
-- =========================================================

-- 01. DATABASE AND TABLE SETUP
CREATE DATABASE IF NOT EXISTS telco_churn;
USE telco_churn;

-- Reset this project's table so the script can be run again.
-- This permanently deletes any existing data in customers.
DROP TABLE IF EXISTS customers;

CREATE TABLE IF NOT EXISTS customers (
    customerID VARCHAR(20),
    gender VARCHAR(10),
    SeniorCitizen INT,
    Partner VARCHAR(5),
    Dependents VARCHAR(5),
    tenure INT,
    PhoneService VARCHAR(5),
    MultipleLines VARCHAR(25),
    InternetService VARCHAR(15),
    OnlineSecurity VARCHAR(25),
    OnlineBackup VARCHAR(25),
    DeviceProtection VARCHAR(25),
    TechSupport VARCHAR(25),
    StreamingTV VARCHAR(25),
    StreamingMovies VARCHAR(25),
    Contract VARCHAR(20),
    PaperlessBilling VARCHAR(5),
    PaymentMethod VARCHAR(30),
    MonthlyCharges DECIMAL(10,2),
    TotalCharges VARCHAR(15),
    Churn VARCHAR(5),
    UNIQUE KEY unique_customer (customerID)
);

-- Should be done both at MySQL and at Client(may require admin permission, you can do it in mysql command line client).
SET GLOBAL local_infile = 1;

-- To look if local_infile is on in MySQL
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- 02. DATA IMPORT
-- LOAD DATA LOCAL INFILE LOCAL INFILE require LOCAL INFILE to be enabled on both the MySQL server and the client. 
-- Load procedure to load data from the dataset csv.
-- Update the CSV path before running this section.
LOAD DATA LOCAL INFILE 'C:/path/to/telco_churn.csv' 
INTO TABLE customers 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(customerID, gender, SeniorCitizen, Partner, Dependents, tenure, PhoneService,
 MultipleLines, InternetService, OnlineSecurity, OnlineBackup, DeviceProtection,
 TechSupport, StreamingTV, StreamingMovies, Contract, PaperlessBilling,
 PaymentMethod, MonthlyCharges, TotalCharges, Churn);
 
-- 03. DATA QUALITY CHECKS
-- Check row count, duplicate IDs, blank values, and categories.
SELECT * FROM customers;
SELECT count(*) FROM customers;
SELECT count(DISTINCT customerID) FROM customers;

SELECT count(*) FROM customers WHERE TotalCharges = '';

-- 04. DATA CLEANING
UPDATE customers SET TotalCharges = NULL WHERE TRIM(TotalCharges) = '';
ALTER TABLE customers MODIFY COLUMN TotalCharges DECIMAL(10,2);
SELECT count(*) FROM customers WHERE TotalCharges IS NULL;

-- 05. PROBLEMS AND HYPOTHESIS
-- Problems
	-- Why is customer churn happening?
	-- What drives customer churn?
	-- Can customers who churn be categorized? Or do they have similar attributes?
-- Hypothesis
	-- 	H1a	Contract type Month-to-month = no penalty to leave (switching cost)
	-- 	H1b	Contract type + tenure Month-to-month = mostly new/trial customers
	-- 	H2	Add-on services	More add-ons = more integrated = higher switching cost
	-- 	H3	Internet service type Fiber = premium price + more competitive alternatives
	-- 	H4a	Senior + TechSupport = Tech frustration without support
	-- 	H4b	Senior + MonthlyCharges = Price sensitivity
	-- 	H5	Payment method	Manual payment = natural monthly "reconsider" point vs. autopay inertia
 
 
-- Analysis
-- 06. HYPOTHESIS 1: CONTRACT AND TENURE
-- Hypothesis 1 customers are those who have month to month contract type because: 
-- 1. The switching cost is low. Expectation = churn level is stable across all tenure level within month to month contract, and higher compared to other contract type. 
-- 2. They are new customer who are just trying out the services. Expectation = churn level is declining as tenure increase in month to month contract.

-- Queries and Findings
-- Total customers vs Churned Customers
SELECT COUNT(*) AS total_customers,
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(100 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS Pct_churn_rate
FROM customers; 
-- about 26.54% of total customers churn.

-- H1a testing
-- Month to Month Churned customers vs Month to Month customers
SELECT 
COUNT(*) AS 'Total month to month customers',
SUM(CASE WHEN Churn = 'Yes' and Contract = 'Month-to-Month' THEN 1 ELSE 0 END) AS 'Month to Month churned customers',
ROUND(100 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS 'pct Month to Month churn rate'
FROM customers WHERE Contract = 'Month-to-Month' ; 
-- the customers with mtm contract that churn is about 43% of all mtm customers.

-- Month to Month Churn to Total Churn
SELECT `Month to Month Churn`, `Total Churn`, ROUND(100 * `Month to Month Churn` / `Total Churn`, 2) as 'pct month to Month Churn to Total Churn' 
FROM 
(SELECT COUNT(*) as 'Month to Month Churn', 
(SELECT COUNT(*) FROM customers WHERE churn = 'Yes') as 'Total Churn' 
FROM customers WHERE churn = 'Yes' AND Contract = 'Month-to-month') as tablec;
-- the customers that churn with mtm contract is about 88% out of all the churned customers.


-- H1b testing
SELECT COUNT(churn) "churn_count", churn, CASE 
WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
ELSE '4. 25+ months'
END AS tenure_bucket
FROM customers 
WHERE Contract = 'Month-to-month'
GROUP BY tenure_bucket, churn
ORDER BY tenure_bucket ASC, churn DESC;

SELECT ROUND(SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) / count(*) * 100, 2) as 'pct mtm churn rate per bucket', 
count(*) as 'Total mtm customers', 
CASE 
WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
ELSE '4. 25+ months'
END AS tenure_bucket
FROM customers 
WHERE Contract = 'Month-to-month'
GROUP BY tenure_bucket
ORDER BY tenure_bucket;
-- the churn rate of customers with mtm contract has a declining trend as tenure increases, 
-- with the earliest buckets having 55% and the longest having 30% churn rate with the difference of about 25%.     

SELECT ROUND(SUM(CASE WHEN Churn='Yes' THEN 1 ELSE 0 END) / count(*) * 100, 2) as 'pct churn rate per bucket', 
count(*) as 'Total Customer per Bucket', Contract as 'contract type', 
CASE 
WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
ELSE '4. 25+ months'
END AS tenure_bucket
FROM customers
GROUP BY tenure_bucket, Contract
ORDER BY tenure_bucket, Contract;   
-- the churn rate for the +25 months for mtm is relatively higher compared to other contract type.


-- Conclusion and recommendation=
-- H1a (switching cost) = Accepted. Contract type has an effect on churn independent of tenure. At matched tenure (25+ months), month-to-month
-- customers still churn at 30.86%, versus 11.89% (one year) and 3.12% (two year), a 10x spread that tenure alone cannot explain.

-- H1b (newness/trial) = Accepted. Within month-to-month customers only, churn declines steadily as tenure increases: from 55.20% (0-6 months)
-- to 30.86% (25+ months). This pattern would not exist if switching cost were the only mechanism at work.

-- Both mechanisms are real and operate simultaneously, not competing, explanations: newness explains the early decline, low switching cost
-- explains why churn stays elevated even after 25+ months.

-- Finding: month-to-month contracts represent 55% of the customer base but account for 88.55% of all churn, by far the highest-impact segment in this analysis.

-- Recommendation: two distinct actions, targeting the two mechanisms separately.
-- 1. Onboarding (targets H1b): proactive support and engagement in a customer's first 6 months, when churn is highest (55.20%).
-- 2. Contract-conversion incentive (targets H1a): offer a discount or perk to convert month-to-month customers to 1-2 year plans, 
-- timed around month 6-12, once they've shown signs of staying.

-- To be considered: conversion incentives reduce margin per customer. Recommend testing at small scale before a full rollout, to confirm the retention
-- gain outweighs the discount cost.

-- ---------------------------------------------
-- 07. HYPOTHESIS 2: ADD-ON SERVICES
-- H2 Customers with more Add-on-services are more likely to be integrated to company services or ecosystem which also means they have higher switching cost. 
-- Expectation customers with more Add-on-services have a lower churn rate compared to customers with less add-on-services.

-- Queries and Findings
-- Customer with and without Internet Services
SELECT `Cust with Internet services`, `Cust without Internet services`, 
ROUND(`Cust with Internet services` / (`Cust with Internet services` + `Cust without Internet services`) * 100, 2) 'pct rate of cust with inet service',
ROUND(`Cust without Internet services` / (`Cust with Internet services` + `Cust without Internet services`) * 100, 2) 'pct rate of cust without inet service'
FROM (SELECT SUM(CASE WHEN InternetService != 'No' THEN 1 ELSE 0 END) 'Cust with Internet services',
SUM(CASE WHEN InternetService = 'No' THEN 1 ELSE 0 END) 'Cust without Internet services' 
FROM customers) AS inet_table;
-- about 78% of customers have internet services

-- customer churn rate based on the number of add on service.
SELECT 
`Add_on_service_count`, 
`Total_customers_with_internet_service_per_bucket`, 
`amount_of_churn`, 
ROUND(`amount_of_churn` / `Total_customers_with_internet_service_per_bucket` * 100, 2) AS churn_pct FROM
(SELECT 
COUNT(*) AS Total_customers_with_internet_service_per_bucket, 
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) as amount_of_churn, 
(OnlineSecurity = 'Yes' ) + (OnlineBackup = 'Yes') + (DeviceProtection = 'Yes') + (TechSupport = 'Yes') + (StreamingTV = 'Yes') + (StreamingMovies = 'Yes') 
AS Add_on_service_count
FROM customers 
WHERE InternetService != 'No'
GROUP BY Add_on_service_count
ORDER BY Add_on_service_count
) AS add_on_service_table;
-- churn rate are trending down as add on services increases. from 52% churn rate for group with 0 add on service, to 5% for group with 6 add on service.

-- average add on service based on customer tenure(bucketed)
SELECT CASE 
WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
ELSE '4. 25+ months'
END AS tenure_bucket,
AVG((OnlineSecurity = 'Yes' ) + (OnlineBackup = 'Yes') + (DeviceProtection = 'Yes') + (TechSupport = 'Yes') + (StreamingTV = 'Yes') + (StreamingMovies = 'Yes'))
AS Average_Add_on_service
FROM customers
WHERE InternetService != 'No'
GROUP BY tenure_bucket
ORDER BY tenure_bucket; 
-- The higher the tenure, the higer the average add on service the customer have.

-- customer churn rate based on the number of add on service for +25 month tenure group with internet services.
SELECT `Add_on_service_count`, 
COUNT(*) as 'Total customer in +25 M bucket', 
SUM(`Churn`) as 'Total churn in +25 M bucket', 
ROUND(SUM(`Churn`) / COUNT(*)  * 100, 2) AS 'pct churn rate for +25 M bucket'
FROM (SELECT 
CASE 
WHEN Churn = 'Yes' THEN 1 ELSE 0 END AS Churn,
CASE 
WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
ELSE '4. 25+ months'
END AS tenure_bucket,
(OnlineSecurity = 'Yes' ) + (OnlineBackup = 'Yes') + (DeviceProtection = 'Yes') + (TechSupport = 'Yes') + (StreamingTV = 'Yes') + (StreamingMovies = 'Yes')
AS Add_on_service_count
FROM customers
WHERE InternetService != 'No') AS add_on_service_on_tenure 
WHERE `tenure_bucket` = '4. 25+ months'
GROUP BY Add_on_service_count
ORDER BY Add_on_service_count; 
-- filtering to customers with +25 months tenure, churn rate become more tight with group 0 having churn rate of 25% to 5% from group 6.

-- Conclusion and recommendation= 
-- H2 = accepted, weak, Churn rate declines consistently as add-on count increases, from 52.24% (0 add-ons) to 5.28% (6 add-ons) across all customers with internet services.

-- However Add-on count correlates with tenure (average add-ons rises from 1.13 in the 0-6 month bucket to 3.44 in the 25+ month bucket), so part of the raw
-- effect may reflect tenure rather than add-ons themselves.

-- Controlling for tenure (25+ months only), the same declining pattern holds, but the effect shrinks to roughly 43% of its original size: churn falls from
-- 25.00% (0 add-ons) to 5.04% (6 add-ons), versus 52.24% to 5.28% uncontrolled. This confirms add-ons matter independently of tenure, but the true effect is
-- smaller than the raw numbers suggest.

-- Recommendation: Since this remains an association, not a proven causal effect, it is recommended to do a controlled test than a full rollout: 
-- offer a subset of new customers a free trial or discounted add-on bundle, and compare their churn against a similar group that didn't receive the offer. 
-- This tests whether add-ons actually reduce churn, or are simply a symptom of customers who were already likely to stay.

-- ---------------------------------------------
-- 08. HYPOTHESIS 3: INTERNET SERVICE
-- H3 Customers with fiber optic internet service are more likely to churn then the one with DSL, because fiber optic are way more expensive than DSL which give them more reason to price shop
-- not only that fiber tends to have more competing providers offering something similar, so it's easier for a fiber customer to switch.
-- Expectation customers with fiber internet service have a higher churn rate then the one with DSL.

-- Queries and Findings
SELECT InternetService, COUNT(*) Total_Customers, 
ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) pct_share_of_customers, 
AVG(MonthlyCharges) avg_monthly_charges, AVG(TotalCharges) avg_total_charges FROM customers
GROUP BY InternetService;
-- fiber optic verified the most expansive internet services.
-- most customers use fiber optic around 44% of total customers.

SELECT InternetService, COUNT(*) Total_Customers,
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) pct_churn_Rate 
FROM customers
GROUP BY InternetService;
-- Fiber optic by total have the highest churn rate around 42%, with DSL churn rate aroound 19%.

SELECT Contract, InternetService, COUNT(*) Total_Customers,
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) pct_churn_Rate 
FROM customers
GROUP BY Contract, InternetService
ORDER BY InternetService, Contract;
-- by contract type, churn rate have a declining trend with mtm contract having the highest churn rate, and 2 year contract having the lowest churn rate,
-- but still the churn rate of Fiber is still way higher compared to DSL across all contract type.

-- Conclusion and recommendation= 
-- H3 = Accepted, Fiber optic customers churn at 41.89%, versus 18.96% for DSL and this gap holds at every contract level after controlling 
-- with contract type (a known major churn driver), from 1.7x at month-to-month up to 3.8x at two-year contracts (increase).

-- However the ORIGINAL mechanism proposed (customer price sensitivity from fiber's premium pricing) has not actually been tested, only the price premium
-- itself ($91.50 vs $58.10) and the churn gap were confirmed. This dataset has no service-quality or complaint data, so an equally plausible
-- alternative (fiber reliability/service issues rather than price) cannot be ruled out with the data available.

-- Recommendation: Because the true driver is unresolved, recommend targeted customer research (exit surveys or interviews specifically with churned
-- fiber customers) to determine whether price or service quality is the dominant driver, before committing budget to either a pricing response
-- or a service-improvement initiative. Fiber optic represents 44% of the customer base, so whichever cause is confirmed, it's a high-impact fix.

-- ---------------------------------------------
-- 09. HYPOTHESIS 4: SENIOR CUSTOMERS
-- H4a: Senior citizens churn more because they struggle more with technology, and lacking a tech-support add-on leaves that frustration unresolved. 
-- Prediction: among senior citizens, churn rate is higher for those without TechSupport than for those with it.

-- H4b: Senior citizens churn more because they're more price-sensitive and rising bills push them out. 
-- Prediction: among senior citizens, churn rate is higher for those with high MonthlyCharges than those with low MonthlyCharges.

-- Queries and Findings
-- H4a testing
SELECT 
SUM(SeniorCitizen) Total_Seniors,
COUNT(*) - SUM(SeniorCitizen) as Total_non_seniors, 
COUNT(*) Total_customers,
ROUND(SUM(SeniorCitizen) / COUNT(*) * 100, 2) Seniors_Rate,
SUM(CASE WHEN Churn = 'Yes' AND SeniorCitizen = 1 THEN 1 ELSE 0 END) AS Seniors_Churn,
SUM(CASE WHEN Churn = 'Yes' AND SeniorCitizen = 0 THEN 1 ELSE 0 END) AS Non_seniors_Churn,
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS Total_Churn,
ROUND(SUM(CASE WHEN Churn = 'Yes' AND SeniorCitizen = 1 THEN 1 ELSE 0 END) / SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS 'pct_Seniors_Churn/Total_Churn',
ROUND(SUM(CASE WHEN Churn = 'Yes' AND SeniorCitizen = 0 THEN 1 ELSE 0 END) / SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100, 2) AS 'pct_Non_Seniors_Churn/Total_Churn',
ROUND(SUM(CASE WHEN Churn = 'Yes' AND SeniorCitizen = 1 THEN 1 ELSE 0 END) / SUM(SeniorCitizen) * 100, 2) as 'pct_Seniors_churn/Total_Seniors',
ROUND(SUM(CASE WHEN Churn = 'Yes' AND SeniorCitizen = 0 THEN 1 ELSE 0 END) / (COUNT(*) - SUM(SeniorCitizen)) * 100, 2) as 'pct_Non_Seniors_churn/Total_Non_Seniors'
FROM customers;
-- Seniors generally churn more than non seniors 42% vs 24%, amounting to 25% of total customers churn.

SELECT TechSupport, COUNT(*) total_per_group, 
(SELECT COUNT(*) FROM customers WHERE SeniorCitizen  = 1) as total_senior_citizen,
ROUND(COUNT(*) / (SELECT COUNT(*) FROM customers WHERE SeniorCitizen  = 1) * 100, 2) pct_senior_techsupp_rate
FROM customers
WHERE SeniorCitizen  = 1
GROUP BY TechSupport;
-- 52 (4.6%) out of 1142 of seniors don't have internet services, meaning they can't and don't need TechSupport for their internet services.

SELECT TechSupport, Churn, COUNT(*) seniors_in_group, 
SUM(COUNT(*)) OVER(PARTITION BY Churn) Total_with_same_churn_status,
SUM(COUNT(*)) OVER(PARTITION BY TechSupport) Total_with_same_tech_support,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY Churn) * 100, 2) pct_of_churn_status_group,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY TechSupport) * 100, 2) pct_of_tech_support_group
FROM customers
WHERE SeniorCitizen  = 1 AND InternetService != 'No'
GROUP BY TechSupport, Churn
ORDER BY Churn DESC, TechSupport;
-- Among senior customers with internet service who churned, 420 of 471 (about 89%) did not have TechSupport.
-- Within this same population, about 51% (420 of 830) of seniors without TechSupport churned, compared to about 20% for seniors with TechSupport(51 of 260).

-- Testing with H1b in mind
SELECT CASE 
WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
ELSE '4. 25+ months'
END AS tenure_bucket,
COUNT(*) AS total,
SUM(CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END) AS has_techsupport,
ROUND(100 * SUM(CASE WHEN TechSupport = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_with_techsupport
FROM customers
WHERE SeniorCitizen = 1 AND InternetService != 'No'
GROUP BY tenure_bucket
ORDER BY tenure_bucket;
-- the higher the tenure the more likely the customers to have tech support.

SELECT TechSupport, Churn, COUNT(*) seniors_in_group, 
SUM(COUNT(*)) OVER(PARTITION BY Churn) Total_with_same_churn_status,
SUM(COUNT(*)) OVER(PARTITION BY TechSupport) Total_with_same_tech_support,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY Churn) * 100, 2) pct_of_churn_status_group,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER(PARTITION BY TechSupport) * 100, 2) pct_of_tech_support_group
FROM (SELECT *,
CASE 
WHEN tenure BETWEEN 0 AND 6 THEN '1. 0-6 months'
WHEN tenure BETWEEN 7 AND 12 THEN '2. 7-12 months'
WHEN tenure BETWEEN 13 AND 24 THEN '3. 13-24 months'
ELSE '4. 25+ months'
END AS tenure_bucket FROM customers) AS With_tenure_bucket
WHERE `SeniorCitizen`  = 1 AND `InternetService` != 'No' AND `tenure_bucket` = '4. 25+ months'
GROUP BY `TechSupport`, `Churn`
ORDER BY `Churn` DESC, `TechSupport`;
-- filtered to 25+ months tenure, among senior customers with internet service who churned, 144 of 176 (about 82%) did not have TechSupport.
-- Within this same population, about 36% (144 of 404) of seniors without TechSupport churned.
-- the amount of people with tech support that didn't churn are around 36% when filterd with 25+ month tenure, showing that H1b at work.

-- H4b testing
SELECT AVG(MonthlyCharges) AS median_monthly_charge
FROM (
SELECT
MonthlyCharges,
ROW_NUMBER() OVER (ORDER BY MonthlyCharges) AS row_num,
COUNT(*) OVER () AS row_count
FROM customers
WHERE SeniorCitizen = 1
) AS ranked_charges
WHERE row_num IN (
FLOOR((row_count + 1) / 2),
FLOOR((row_count + 2) / 2)
);
-- Monthly Charges Median = 84.85

SELECT H_or_L,
COUNT(*) Total_senior_customers, 
SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) Senior_churn,
ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) pct_churn_rate
FROM (SELECT *, CASE WHEN MonthlyCharges >= 84.85 THEN 'High' ELSE 'Low' END AS H_or_L FROM customers) AS Seniors_grouped_highlow 
WHERE SeniorCitizen = 1 
GROUP BY `H_or_L`;
-- Divided into 2 group, based on the median of montly charge, the churn rate between each group is basically the same.

-- Conclusion and recommendation= 
-- H4a = Accepted. Out of the total senior customers with internet services that churn, about 89% of them don't have tech support, not only that, but comparing the 
-- churn rate of seniors that don't have tech support vs the ones that have it shows a massive gap of 50.60% vs 19.62%.

-- H4b = Rejected. The cost or the amount of monthly charge doesn't seem to affect the senior customer decision to churn, 
-- Senior customers above and below the median monthly charge had nearly identical churn rates (41.75% vs. 41.61%).
-- This analysis found no evidence of a relationship between monthly charges and senior-customer churn using this high/low split.

-- This would suggest that senior citizens are probably stressed with the internet service technology and need tech support to deal with it.

-- Recommendation: It is suggested to try market, introduce, or give a trial of tech support service to the seniors so they know about this service and don't feel 
-- too confused with the internet service technology, which might lead them to be stressed and churn. Seeing if there's an actual effect to the churn level of seniors.

-- ---------------------------------------------
-- 10. HYPOTHESIS 5: PAYMENT METHOD
-- H5: Automatic payment (bank transfer/credit card) creates passive retention through inertia, customers don't actively re-decide each month to continue or leave. 
-- Manual payment (electronic check/mailed check) forces a monthly re-commitment, creating a natural pause point to reconsider and leave.
-- Prediction: churn rate is higher for electronic check / mailed check customers than for bank transfer / credit card customers.

-- Queries and Findings
SELECT 
SUM(CASE WHEN `auto_or_manual` = 'Automatic' THEN 1 ELSE 0 END) Total_Auto,
SUM(CASE WHEN `auto_or_manual` != 'Automatic' THEN 1 ELSE 0 END) Total_Manual,
ROUND(SUM(CASE WHEN `auto_or_manual` = 'Automatic' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) pct_auto_Rate,
ROUND(SUM(CASE WHEN `auto_or_manual` != 'Automatic' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) pct_manual_Rate
FROM
(SELECT *, CASE WHEN PaymentMethod LIKE '%automatic%' THEN 'Automatic' ELSE 'Manual' END AS auto_or_manual FROM customers) 
auto_or_manual_table;
-- total customers with auto and manual payment method are spread quite evenly.

SELECT `auto_or_manual`, ROUND(SUM(CASE WHEN `Churn` = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) pct_churn_rate_each_group
FROM
(SELECT *, 
CASE WHEN PaymentMethod LIKE '%automatic%' THEN 'Automatic' ELSE 'Manual' END AS auto_or_manual 
FROM customers) auto_or_manual_table 
GROUP BY `auto_or_manual`;
-- churn rate of manual payment method(around 35%) is around double the automatic(around 16%)

SELECT PaymentMethod, COUNT(*) Total,
SUM(CASE WHEN Churn ='Yes' THEN 1 ELSE 0 END) AS Churn_Count,
ROUND(SUM(CASE WHEN Churn ='Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS pct_churn_rate_per_payment_method
FROM customers
GROUP BY PaymentMethod;
-- looking at the payment method, the churn rate are mostly even except electornic check(around 45%) which has more than double churn rate compared to other payment method(around 15%-19%).

SELECT PaymentMethod, Contract, COUNT(*) Count, SUM(COUNT(*)) OVER() Overall_Total,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) pct_rate_to_total,
SUM(CASE WHEN Churn ='Yes' THEN 1 ELSE 0 END) AS Churn_Count,
ROUND(SUM(CASE WHEN Churn ='Yes' THEN 1 ELSE 0 END)  / COUNT(*) * 100, 2) pct_churn_rate
FROM customers
GROUP BY PaymentMethod, Contract
ORDER BY PaymentMethod, Contract;
-- looking at contract type still mtm dominate the customer churn with downtrend of churn rate the longer the contract type is. 
-- across all contract method electronic check is still the one dominating the customer churn.

-- Conclusion and recommendation= 
-- H5: Partially rejected. The Churn rate of manual(34.67%) is higher than automatic(15.99%), initially appeared to support the hypothesis, but breaking out each
-- payment method individually shows mailed check (19.11%) sits close to both automatic methods (16.71%, 15.24%) — not elevated like electronic check
-- (45.29%). The effect is not "manual payment" broadly; it is specific to electronic check.

-- New hypothesis: Most people who use electronic checks are those who haven't committed to staying with the company and are only trying out the services.
-- Electronic check customers are 78% mtm, versus 35-55% for the other three payment methods in mtm, suggesting electronic check may be a low-friction default for customers

-- Controlled with mtm contracts, the churn rate of electronic check is about 54% while the rest is around 31-34%. Electronic check is still the anomaly.

-- The specific cause remains unconfirmed. One plausible explanation is that electronic check is the easiest option for non-committed, trial
-- customers. An equally plausible alternative, common in telecom churn data, is that electronic check payments fail more often (insufficient funds,
-- expired details), leading to involuntary cancellations recorded as churn. This dataset has no payment-failure or cancellation-reason field, so the
-- two explanations cannot be distinguished with the data available.

-- Recommendation: because the two explanations point to different fixes (payment friction for the trial-customer story vs failed-payment and
-- reactivation handling for the involuntary-churn story), recommend investigating actual cancellation reasons for electronic check customers
-- (via billing/support systems and cancellation-reason, if available) before commitment.

-- ---------------------------------------------
-- 11. OVERALL RECOMMENDATIONS
-- 1. Focus on month-to-month customers (H1).
-- Month-to-month customers account for about 88.55% of churn in this dataset. Prioritize two tests:
-- a. Improve onboarding and support during customers' first six months, when churn is highest within this contract group.
-- b. Test a contract-conversion offer for month-to-month customers, perhaps around months 6–12.
-- Track retention and the cost of any discounts to see whether the offers provide enough value to continue.

-- 2. Test proactive TechSupport outreach for senior customers (H4a).
-- Among senior customers with internet service, churn is lower for those with TechSupport than for those without it. This is an association and
-- does not show that TechSupport prevents churn. Pilot the offer and compare outcomes with a similar group that does not receive it. The analysis
-- does not establish that newer senior customers benefit more, so treat that as a question for the pilot rather than a confirmed finding.

-- 3. Investigate why fiber customers churn before choosing an intervention (H3).
-- Fiber customers make up about 44% of the customer base and have a higher churn rate than DSL customers, including within contract groups. The
-- dataset cannot show whether price, service quality, or another factor explains the difference. Use exit surveys, interviews, or support records
-- to investigate before committing resources to pricing or service changes.
--
-- 4. Pilot add-on offers before considering a broader rollout (H2).
-- Churn is lower among customers with more add-on services, but the pattern is also related to tenure and does not establish that add-ons reduce churn.
-- Offer a trial or discounted bundle to a test group and compare its results with a similar control group before making a larger investment.

-- 5. Investigate electronic-check churn (H5).
-- Electronic-check customers have a higher churn rate than customers using other payment methods, including within the month-to-month group. The
-- dataset does not identify the reason. Review billing records, payment failures, and cancellation reasons before deciding whether the right
-- response involves payment support or another change.

-- ---------------------------------------------
-- 12. LIMITATIONS
-- 1. Single snapshot, no dates — can't distinguish a worsening trend from a stable pattern.

-- 2. No service-quality, complaint, or payment-failure data. several findings (H3, H5) have a real, confirmed pattern but an unconfirmed cause, 
-- because this dataset can't distinguish between competing explanations.

-- 3. Association, not causation, throughout — every recommendation above that involves a new intervention (H2, H3, H5) is explicitly framed as 
-- "test/investigate first," not "roll out," because this is observational data, not an experiment.