-- Staging Table: Raw Transactions Data
CREATE TABLE transactions_stg (
    transaction_id VARCHAR(50), 
    cust_id VARCHAR(50), 
    tran_date VARCHAR(50), 
    prod_subcat_code VARCHAR(50),
    prod_cat_code VARCHAR(50), 
    qty VARCHAR(50), 
    rate VARCHAR(50), 
    tax VARCHAR(50), 
    total_amt VARCHAR(50), 
    store_type VARCHAR(50)
);

-- Staging Table: Raw Customer Data
CREATE TABLE customer_stg (
    customer_Id VARCHAR(50),
    DOB VARCHAR(50),
    Gender VARCHAR(10),
    city_code VARCHAR(50)
);

-- Staging Table: Raw Product Category Info
CREATE TABLE prod_cat_info_stg (
    prod_cat_code VARCHAR(50),
    prod_cat VARCHAR(100),
    prod_sub_cat_code VARCHAR(50),
    prod_subcat VARCHAR(100)
);
