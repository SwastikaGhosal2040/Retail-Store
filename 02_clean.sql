
-- ============================================================
-- PROJECT: Retail Store Analytics
-- FILE: 02_clean.sql
-- DATABASE: MySQL
-- PURPOSE:
--   1. Clean all three datasets.
--   2. Convert raw text into appropriate data types.
--   3. Remove exact duplicate transaction rows.
--   4. Identify returns and calculate customer age.
--   5. Establish primary keys, foreign keys, and indexes.
--   6. Validate all major findings documented in the README.
-- ============================================================

-- Select the project database so every command below runs in the correct database.
USE retail_store_analytics;

-- ============================================================
-- STEP 1: REMOVE PREVIOUSLY GENERATED CLEAN TABLES
-- Original staging tables are preserved.
-- This is safe for the imported raw data, but it does rebuild/delete prior clean tables.
-- ============================================================

-- DROP TABLE removes a table. IF EXISTS prevents an error if it is not there yet.
-- These are CLEAN tables only; the *_stg staging/raw tables are not deleted.
-- Re-running this file rebuilds these three clean tables from scratch.
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS prod_cat_info;


-- ============================================================
-- STEP 2: CLEAN CUSTOMER DATA
-- Expected source rows: 5,647.
-- Blank gender and city values are preserved as NULL.
-- Age is calculated as of 28-Feb-2014.
-- ============================================================

-- CREATE TABLE defines the clean table and each column's data type.
-- INT = whole number; DATE = date; VARCHAR = text. NOT NULL means required.
-- PRIMARY KEY uniquely identifies each customer; INDEX can speed up city lookups.
CREATE TABLE customer (
    customer_id INT NOT NULL,
    dob DATE,
    gender VARCHAR(20),
    city_code INT,
    age_at_data_end INT,
    PRIMARY KEY (customer_id),
    INDEX idx_customer_city_code (city_code)
) ENGINE = InnoDB;

-- INSERT INTO ... SELECT copies cleaned values from customer_stg into customer.
-- TRIM removes surrounding spaces; NULLIF(text, '') changes a blank string to NULL.
-- CAST converts text to a number; STR_TO_DATE converts text to a DATE.
-- TIMESTAMPDIFF(YEAR, DOB, end_date) calculates age in whole years.
INSERT INTO customer (
    customer_id,
    dob,
    gender,
    city_code,
    age_at_data_end
)
SELECT
    CAST(NULLIF(TRIM(customer_Id), '') AS UNSIGNED),
    STR_TO_DATE(
        NULLIF(TRIM(DOB), ''),
        '%d-%m-%Y'
    ),
    NULLIF(TRIM(Gender), ''),
    CAST(NULLIF(TRIM(city_code), '') AS UNSIGNED),
    CASE
        WHEN STR_TO_DATE(
            NULLIF(TRIM(DOB), ''),
            '%d-%m-%Y'
        ) IS NOT NULL
        THEN TIMESTAMPDIFF(
            YEAR,
            STR_TO_DATE(
                NULLIF(TRIM(DOB), ''),
                '%d-%m-%Y'
            ),
            '2014-02-28'
        )
        ELSE NULL
    END
FROM customer_stg;


-- ============================================================
-- STEP 3: CLEAN PRODUCT CATEGORY DATA
-- Both category and subcategory codes form the primary key.
-- Expected combinations: 23.
-- ============================================================

-- A composite primary key uses TWO columns together to identify one row.
-- A category code alone can repeat across subcategories, so both codes are needed.
CREATE TABLE prod_cat_info (
    prod_cat_code INT NOT NULL,
    prod_cat VARCHAR(100),
    prod_sub_cat_code INT NOT NULL,
    prod_subcat VARCHAR(100),
    PRIMARY KEY (
        prod_cat_code,
        prod_sub_cat_code
    )
) ENGINE = InnoDB;

-- DISTINCT keeps one copy of each unique category/subcategory combination.
-- The staging table is left unchanged; cleaned values are inserted into prod_cat_info.
INSERT INTO prod_cat_info (
    prod_cat_code,
    prod_cat,
    prod_sub_cat_code,
    prod_subcat
)
SELECT DISTINCT
    CAST(NULLIF(TRIM(prod_cat_code), '') AS UNSIGNED),
    NULLIF(TRIM(prod_cat), ''),
    CAST(NULLIF(TRIM(prod_sub_cat_code), '') AS UNSIGNED),
    NULLIF(TRIM(prod_subcat), '')
FROM prod_cat_info_stg;


-- ============================================================
-- STEP 4: CLEAN TRANSACTION DATA
-- Expected raw rows: 23,053.
-- Expected exact duplicate rows removed: 13.
-- Expected clean rows: 23,040.
--
-- Deduplicate the original staging rows BEFORE conversion.
-- This ensures rows with different raw representations are
-- not accidentally treated as exact duplicates.
--
-- transaction_id is NOT a primary key because a sale and
-- its return can share the same transaction ID.
-- ============================================================

-- DECIMAL stores exact decimal values suitable for money; BIGINT stores large integers.
-- BOOLEAN stores true/false (in MySQL it is represented numerically).
-- Foreign keys enforce that each transaction references an existing customer/product.
-- Indexes can make joins and date/customer filtering faster.
CREATE TABLE transactions (
    transaction_id BIGINT NOT NULL,
    cust_id INT NOT NULL,
    tran_date DATE,
    prod_subcat_code INT,
    prod_cat_code INT,
    Qty INT,
    Rate DECIMAL(12,2),
    Tax DECIMAL(12,2),
    total_amt DECIMAL(14,2),
    Store_type VARCHAR(100),
    is_return BOOLEAN NOT NULL,

    INDEX idx_transactions_cust_id (cust_id),

    INDEX idx_transactions_product (
        prod_cat_code,
        prod_subcat_code
    ),

    INDEX idx_transactions_date (tran_date),

    CONSTRAINT fk_transactions_customer
        FOREIGN KEY (cust_id)
        REFERENCES customer(customer_id),

    CONSTRAINT fk_transactions_product
        FOREIGN KEY (
            prod_cat_code,
            prod_subcat_code
        )
        REFERENCES prod_cat_info(
            prod_cat_code,
            prod_sub_cat_code
        )
) ENGINE = InnoDB;

-- This INSERT converts staging text fields to numeric/date types.
-- REPLACE changes '/' to '-' so both day-first date formats can use one parser.
-- STR_TO_DATE(..., '%d-%m-%Y') reads day-month-year, not month-day-year.
-- Qty < 0 is used as the return rule, stored in the is_return column.
-- The derived table named raw uses DISTINCT across all 10 source fields to remove
-- exact duplicate source rows before converting them.
INSERT INTO transactions (
    transaction_id,
    cust_id,
    tran_date,
    prod_subcat_code,
    prod_cat_code,
    Qty,
    Rate,
    Tax,
    total_amt,
    Store_type,
    is_return
)
SELECT
    CAST(NULLIF(TRIM(raw.transaction_id), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(raw.cust_id), '') AS UNSIGNED),

    STR_TO_DATE(
        REPLACE(TRIM(raw.tran_date), '/', '-'),
        '%d-%m-%Y'
    ),

    CAST(NULLIF(TRIM(raw.prod_subcat_code), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(raw.prod_cat_code), '') AS UNSIGNED),
    CAST(NULLIF(TRIM(raw.Qty), '') AS SIGNED),
    CAST(NULLIF(TRIM(raw.Rate), '') AS DECIMAL(12,2)),
    CAST(NULLIF(TRIM(raw.Tax), '') AS DECIMAL(12,2)),
    CAST(NULLIF(TRIM(raw.total_amt), '') AS DECIMAL(14,2)),
    NULLIF(TRIM(raw.Store_type), ''),
    (CAST(NULLIF(TRIM(raw.Qty), '') AS SIGNED) < 0)

FROM (
    SELECT DISTINCT
        transaction_id,
        cust_id,
        tran_date,
        prod_subcat_code,
        prod_cat_code,
        qty,
        rate,
        tax,
        total_amt,
        store_type
    FROM transactions_stg
) AS raw;


-- ============================================================
-- STEP 5: VALIDATE ROW COUNTS AND DUPLICATE REMOVAL
-- Expected: 5,647 customers, 23 product combinations,
-- 23,053 raw transactions, 23,040 clean transactions,
-- and 13 exact duplicate rows removed.
-- ============================================================

-- COUNT(*) counts rows. AS gives the output column a readable name (an alias).
SELECT COUNT(*) AS customer_rows
FROM customer;

SELECT COUNT(*) AS product_category_rows
FROM prod_cat_info;

SELECT COUNT(*) AS raw_transaction_rows
FROM transactions_stg;

SELECT COUNT(*) AS cleaned_transaction_rows
FROM transactions;

-- Compare the raw row count with the number of distinct raw records.
-- The difference is the number of exact duplicate rows removed.
SELECT
    (SELECT COUNT(*) FROM transactions_stg)
    -
    (
        SELECT COUNT(*)
        FROM (
            SELECT DISTINCT
                transaction_id,
                cust_id,
                tran_date,
                prod_subcat_code,
                prod_cat_code,
                Qty,
                Rate,
                Tax,
                total_amt,
                Store_type
            FROM transactions_stg
        ) AS distinct_raw_rows
    ) AS exact_duplicate_rows_removed;


-- ============================================================
-- STEP 6: VALIDATE DATE FORMATS AND CONVERSION
-- Expected range: 25-Jan-2011 to 28-Feb-2014.
-- Both input formats are day-first.
-- ============================================================

-- MIN/MAX find the earliest/latest date; SUM(condition) counts rows meeting a condition.
SELECT
    MIN(tran_date) AS earliest_transaction_date,
    MAX(tran_date) AS latest_transaction_date,
    SUM(tran_date IS NULL) AS missing_clean_dates
FROM transactions;

-- Count nonblank source dates that failed conversion. Ideally this is 0.
SELECT
    SUM(
        NULLIF(TRIM(tran_date), '') IS NOT NULL
        AND STR_TO_DATE(
            REPLACE(TRIM(tran_date), '/', '-'),
            '%d-%m-%Y'
        ) IS NULL
    ) AS invalid_nonblank_transaction_dates
FROM transactions_stg;

-- Check for missing birth dates/ages and implausible negative ages.
SELECT
    SUM(dob IS NULL) AS missing_customer_dobs,
    SUM(age_at_data_end IS NULL) AS missing_customer_ages,
    SUM(age_at_data_end < 0) AS negative_customer_ages
FROM customer;


-- ============================================================
-- STEP 7: VALIDATE RETURNS
-- Expected negative-quantity rows: 2,177.
-- Expected transaction IDs appearing exactly twice: 2,175.
-- ============================================================

-- SUM(condition) counts TRUE conditions: negative-quantity returns vs other rows.
SELECT
    SUM(is_return = TRUE) AS negative_quantity_return_rows,
    SUM(is_return = FALSE) AS non_return_rows
FROM transactions;

-- GROUP BY makes one group per transaction ID; HAVING filters groups after counting.
-- This counts IDs occurring exactly twice; it does not count all duplicate rows.
SELECT COUNT(*) AS transaction_ids_appearing_twice
FROM (
    SELECT transaction_id
    FROM transactions
    GROUP BY transaction_id
    HAVING COUNT(*) = 2
) AS repeated_transaction_ids;


-- ============================================================
-- STEP 8: VALIDATE TAX RULE
-- Documented rule: Tax = 10.5% x Qty x Rate.
-- Two-decimal rounding is applied.
-- ============================================================

-- Compare recorded Tax with Qty * Rate * 10.5%, rounded to two decimals.
-- ABS gives the absolute difference; >= 0.01 flags a difference of at least one cent.
SELECT
    COUNT(*) AS rows_with_tax_and_inputs,
    SUM(
        ABS(Tax - ROUND(Qty * Rate * 0.105, 2)) >= 0.01
    ) AS tax_mismatch_rows
FROM transactions
WHERE Tax IS NOT NULL
  AND Qty IS NOT NULL
  AND Rate IS NOT NULL;

-- Show any mismatched records for investigation. If no rows appear, no mismatches
-- were found under this rule. ORDER BY sorts the results by transaction ID.

SELECT
    transaction_id,
    Qty,
    Rate,
    Tax AS recorded_tax,
    ROUND(Qty * Rate * 0.105, 2) AS expected_tax,
    ROUND(
        Tax - ROUND(Qty * Rate * 0.105, 2),
        2
    ) AS tax_difference
FROM transactions
WHERE Tax IS NOT NULL
  AND Qty IS NOT NULL
  AND Rate IS NOT NULL
  AND ABS(Tax - ROUND(Qty * Rate * 0.105, 2)) >= 0.01
ORDER BY transaction_id;


-- ============================================================
-- STEP 9: VALIDATE MISSING GENDER AND CITY VALUES
-- Expected: 2 missing gender values and 2 missing city codes.
-- Keep NULLs in the data; label them 'Unknown' in reports.
-- ============================================================

-- NULL means missing/unknown. These values are retained rather than deleting customers.
SELECT
    SUM(gender IS NULL) AS missing_gender_rows,
    SUM(city_code IS NULL) AS missing_city_rows
FROM customer;


-- ============================================================
-- STEP 10: VALIDATE CUSTOMER AND PRODUCT REFERENCES
-- A zero count means no unmatched references were found.
-- ============================================================

-- LEFT JOIN keeps every transaction; rows with no customer match have c.customer_id NULL.
-- A result of 0 means all transaction customer IDs match a customer.
SELECT COUNT(*) AS unmatched_customer_rows
FROM transactions AS t
LEFT JOIN customer AS c
    ON t.cust_id = c.customer_id
WHERE c.customer_id IS NULL;

-- A product is matched using BOTH category and subcategory codes.
-- A result of 0 means no transaction has an unmatched product combination.
SELECT COUNT(*) AS unmatched_product_rows
FROM transactions AS t
LEFT JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat_code IS NULL;


-- ============================================================
-- STEP 11: VALIDATE THE TWO-COLUMN PRODUCT JOIN
-- The README's 23,053-row expectation applies to the RAW
-- staging join. The cleaned join is expected to have 23,040
-- rows if all clean transactions match a product combination.
-- A one-column join can multiply rows.
-- ============================================================

-- INNER JOIN returns only matching transaction/product rows.
-- Both codes must match; joining on category alone can multiply rows incorrectly.
SELECT COUNT(*) AS two_column_staging_join_rows
FROM transactions_stg AS t
INNER JOIN prod_cat_info_stg AS p
    ON CAST(t.prod_cat_code AS UNSIGNED) =
       CAST(p.prod_cat_code AS UNSIGNED)
   AND CAST(t.prod_subcat_code AS UNSIGNED) =
       CAST(p.prod_sub_cat_code AS UNSIGNED);

SELECT COUNT(*) AS two_column_clean_join_rows
FROM transactions AS t
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code;


-- ============================================================
-- STEP 12: CHECK MISSING NUMERIC TRANSACTION VALUES
-- These are diagnostics, not automatic row deletions.
-- ============================================================

-- Count missing values in important transaction fields. These checks report issues;
-- they do not delete rows or automatically repair the data.
SELECT
    SUM(transaction_id IS NULL) AS missing_transaction_ids,
    SUM(cust_id IS NULL) AS missing_customer_ids,
    SUM(tran_date IS NULL) AS missing_transaction_dates,
    SUM(Qty IS NULL) AS missing_quantities,
    SUM(Rate IS NULL) AS missing_rates,
    SUM(Tax IS NULL) AS missing_taxes,
    SUM(total_amt IS NULL) AS missing_total_amounts
FROM transactions;


-- ============================================================
-- STEP 13: VERIFY TABLE STRUCTURES AND SAMPLE DATA
-- ============================================================

-- SHOW TABLES lists tables in the selected database. DESCRIBE shows column definitions.
SHOW TABLES;

DESCRIBE customer;
DESCRIBE prod_cat_info;
DESCRIBE transactions;

-- SELECT * displays all columns; LIMIT restricts the preview to a few rows.
SELECT *
FROM customer
LIMIT 5;

SELECT *
FROM prod_cat_info
LIMIT 5;

SELECT *
FROM transactions
LIMIT 10;


-- ============================================================
-- END OF 02_clean.sql
-- ============================================================
