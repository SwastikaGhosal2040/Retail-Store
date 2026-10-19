
-- ============================================================
-- PROJECT: Retail Store Analytics
-- DATABASE: MySQL
-- FILE: 01_schema.sql
-- PURPOSE: Create the database and raw staging tables.
-- ============================================================


-- STEP 1: Create the project database.
-- A database is a container that stores related tables.
-- IF NOT EXISTS means MySQL will not create another database
-- if a database with this name already exists.
-- It does NOT delete or reset the existing database.

CREATE DATABASE IF NOT EXISTS retail_store_analytics;


-- STEP 2: Select the database in which we want to work.
-- USE tells MySQL that the following table commands should
-- operate inside retail_store_analytics.

USE retail_store_analytics;


-- STEP 3: Create the customer staging table.
-- A staging table temporarily stores the original CSV data.
-- VARCHAR means text. We use it here because raw data may
-- contain blanks or values that need cleaning later.
-- Each row represents a customer record.

CREATE TABLE IF NOT EXISTS customer_stg (
    customer_Id VARCHAR(50),  -- Customer's unique identifier
    DOB VARCHAR(50),          -- Date of birth, stored initially as text
    Gender VARCHAR(20),       -- Customer's gender
    city_code VARCHAR(50)     -- Code identifying the customer's city
);


-- STEP 4: Create the transaction staging table.
-- Each row represents a record from Transactions.csv.
-- Numeric values and dates are initially stored as text.
-- We will validate and convert them in 02_clean.sql.

CREATE TABLE IF NOT EXISTS transactions_stg (
    transaction_id VARCHAR(50),    -- Transaction identifier
    cust_id VARCHAR(50),           -- ID of the customer making the transaction
    tran_date VARCHAR(50),         -- Transaction date as text
    prod_subcat_code VARCHAR(50),  -- Product subcategory code
    prod_cat_code VARCHAR(50),     -- Product category code
    Qty VARCHAR(50),               -- Quantity purchased or returned
    Rate VARCHAR(50),              -- Price per unit
    Tax VARCHAR(50),               -- Tax amount
    total_amt VARCHAR(50),         -- Total transaction amount
    Store_type VARCHAR(100)        -- Sales channel or store type
);


-- STEP 5: Create the product category staging table.
-- Each row maps a product category and subcategory to their names.
-- These codes will later be used to join product information
-- with transaction records.

CREATE TABLE IF NOT EXISTS prod_cat_info_stg (
    prod_cat_code VARCHAR(50),      -- Product category code
    prod_cat VARCHAR(100),          -- Category name
    prod_sub_cat_code VARCHAR(50),  -- Product subcategory code
    prod_subcat VARCHAR(100)        -- Subcategory name
);


-- STEP 6: Verify that the correct database is selected.
-- SELECT DATABASE() displays the currently selected database.
-- AS selected_database gives the output column a readable name.

SELECT DATABASE() AS selected_database;


-- STEP 7: Display the tables present in the selected database.
-- SHOW TABLES lists table names; it does not display their data.

SHOW TABLES;


-- STEP 8: Check how many rows are present in each staging table.
-- COUNT(*) counts all rows in a table.
-- These queries check the imported data; they do not change it.

SELECT COUNT(*) AS customer_rows
FROM customer_stg;

SELECT COUNT(*) AS transaction_rows
FROM transactions_stg;

SELECT COUNT(*) AS product_rows
FROM prod_cat_info_stg;


-- STEP 9: Preview the first five customer records.
-- SELECT * means display all columns.
-- LIMIT 5 restricts the output to five rows.
-- This helps us check whether the imported data looks correct.

SELECT *
FROM customer_stg
LIMIT 5;


-- END OF 01_schema.sql
-- NOTE:
-- This script creates the database and staging tables if absent.
-- It does not import CSV files or clean the data.
-- CSV import and data cleaning are separate project tasks.
