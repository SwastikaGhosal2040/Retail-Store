-- 1. Clean Transactions Table (Removes 13 duplicate rows and casts data types)
CREATE TABLE transactions AS
SELECT DISTINCT
    CAST(transaction_id AS BIGINT) AS transaction_id,
    CAST(cust_id AS INT) AS cust_id,
    CAST(REPLACE(tran_date, '/', '-') AS DATE) AS tran_date,
    CAST(prod_subcat_code AS INT) AS prod_subcat_code,
    CAST(prod_cat_code AS INT) AS prod_cat_code,
    CAST(qty AS INT) AS qty,
    CAST(rate AS DECIMAL(10,2)) AS rate,
    CAST(tax AS DECIMAL(10,2)) AS tax,
    CAST(total_amt AS DECIMAL(10,2)) AS total_amt,
    store_type,
    CASE WHEN CAST(qty AS INT) < 0 THEN 1 ELSE 0 END AS is_return
FROM transactions_stg;

-- 2. Clean Customer Table
CREATE TABLE customer AS
SELECT 
    CAST(customer_Id AS INT) AS customer_id,
    CAST(REPLACE(DOB, '/', '-') AS DATE) AS dob,
    CASE WHEN Gender = '' THEN NULL ELSE Gender END AS gender,
    CASE WHEN city_code = '' THEN NULL ELSE CAST(city_code AS INT) END AS city_code
FROM customer_stg;

-- 3. Clean Product Category Table
CREATE TABLE prod_cat_info AS
SELECT 
    CAST(prod_cat_code AS INT) AS prod_cat_code,
    prod_cat,
    CAST(prod_sub_cat_code AS INT) AS prod_sub_cat_code,
    prod_subcat
FROM prod_cat_info_stg;

-- 4. Constraints & Primary/Foreign Keys
ALTER TABLE customer 
  ADD CONSTRAINT pk_customer PRIMARY KEY (customer_id);

ALTER TABLE prod_cat_info 
  ADD CONSTRAINT pk_prod_cat PRIMARY KEY (prod_cat_code, prod_sub_cat_code);

ALTER TABLE transactions 
  ADD CONSTRAINT fk_transactions_customer 
  FOREIGN KEY (cust_id) REFERENCES customer(customer_id);
