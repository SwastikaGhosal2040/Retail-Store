
-- =====================================================
-- PROJECT: Retail Store Analytics
-- FILE: 03_tests.sql
-- PURPOSE: Test the quality of cleaned data.
-- =====================================================

USE retail_store_analytics;

-- Check that MySQL is using the correct database.
SELECT DATABASE() AS current_database;


-- =====================================================
-- Part A, TEST 1: CHECK CLEANED TABLE ROW COUNTS
-- Purpose: Confirm that the cleaned tables contain
-- the expected number of records.
-- =====================================================

SELECT
    'customer' AS table_name,
    COUNT(*) AS row_count
FROM customer

UNION ALL

SELECT
    'prod_cat_info',
    COUNT(*)
FROM prod_cat_info

UNION ALL

SELECT
    'transactions',
    COUNT(*)
FROM transactions;

-- =====================================================
-- Part A, TEST 1: Query Explanation 
-- COUNT(*) counts all rows in a table.
-- UNION ALL combines the results of multiple SELECT statements without removing duplicate result rows.
-- table_name identifies the table, and row_count displays its record count.
-- =====================================================


-- =====================================================
-- Part A, TEST 2: CHECK FOR ORPHAN CUSTOMERS
-- Expected result: 0
-- Purpose: Find transactions linked to nonexistent
-- customers.
-- =====================================================

SELECT
    COUNT(*) AS orphan_customer_rows
FROM transactions AS t
LEFT JOIN customer AS c
    ON t.cust_id = c.customer_id
WHERE c.customer_id IS NULL;

-- =====================================================
-- Part A, TEST 2: Query Explanation 
-- FROM transactions AS t — uses the transactions table and gives it the short alias t
-- LEFT JOIN customer AS c — checks for a matching customer while keeping every transaction in the search.
-- ON t.cust_id = c.customer_id — matches the transaction's customer ID with the customer's ID.
-- WHERE c.customer_id IS NULL — finds transactions for which no matching customer exists.
-- COUNT(*) — counts how many such transactions were found.
-- =====================================================


-- =====================================================
-- Part A, TEST 3: CHECK FOR ORPHAN PRODUCTS
-- Expected result: 0
-- Purpose: Find transactions whose product category
-- and subcategory do not exist in the product table.
-- =====================================================

SELECT
    COUNT(*) AS orphan_product_rows
FROM transactions AS t
LEFT JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat_code IS NULL;

-- =====================================================
-- Part A, TEST 3: Query Explanation
-- 1. LEFT JOIN checks every transaction against the product table.
-- 2. Both product category and subcategory codes must match.
-- 3. WHERE p.prod_cat_code IS NULL identifies unmatched products.
-- 4. COUNT(*) counts the transactions with no matching product.
-- Result: 0 orphan product rows were found, so this test passed.
-- =====================================================


-- =====================================================
-- Part A, TEST 4: CHECK TAX INTEGRITY
-- Expected result: 0 mismatched rows
-- =====================================================

SELECT
    COUNT(*) AS tax_mismatch_rows
FROM transactions
WHERE Tax IS NOT NULL
  AND Qty IS NOT NULL
  AND Rate IS NOT NULL
  AND ABS(Tax - ROUND(0.105 * Qty * Rate, 2)) >= 0.01;

-- =====================================================
-- Part A, TEST 4 : Query Explanation
-- 1. COUNT(*) counts the transaction rows that fail the tax check.
-- 2. FROM transactions specifies the cleaned transaction table.
-- 3. WHERE Tax IS NOT NULL excludes rows with missing tax values.
-- 4. AND Qty IS NOT NULL and AND Rate IS NOT NULL exclude rows
--    where the quantity or rate is missing.
-- 5. ROUND(0.105 * Qty * Rate, 2) calculates expected tax
--    at 10.5%, rounded to two decimal places.
-- 6. ABS(Tax - expected_tax) calculates the absolute difference
--    between recorded tax and expected tax.
-- 7. >= 0.01 selects differences of at least ₹0.01.
-- Result: 0 mismatched rows were found; this test passed.
-- =====================================================


-- =====================================================
-- Part A, TEST 5: CHECK AMOUNT INTEGRITY
-- Expected result: 0 mismatched rows
-- =====================================================

SELECT
    COUNT(*) AS amount_mismatch_rows
FROM transactions
WHERE total_amt IS NOT NULL
  AND Qty IS NOT NULL
  AND Rate IS NOT NULL
  AND Tax IS NOT NULL
  AND ABS(
      ABS(total_amt) - (ABS(Qty * Rate) + Tax)
  ) > 0.01;

-- =====================================================
-- Part A, TEST 5 : Query Explanation
-- 1. COUNT(*) counts transaction rows that fail the amount check.
-- 2. FROM transactions uses the cleaned transaction table.
-- 3. The IS NOT NULL conditions exclude rows with missing
--    total_amt, Qty, Rate, or Tax.
-- 4. ABS(Qty * Rate) calculates the absolute product amount,
--    handling negative quantities for returns.
-- 5. Adding Tax gives the expected total under this rule.
-- 6. ABS(total_amt) makes the recorded total positive for comparison.
-- 7. The outer ABS(...) calculates the difference between the
--    recorded total and the expected total.
-- 8. > 0.01 selects differences greater than 0.01.
-- Result: 0 amount mismatches were found; this test passed.
-- =====================================================


-- =====================================================
-- Part A, TEST 6: FIND RETURNS WITHOUT A MATCHING SALE
-- Expected result: 2 orphan returns
-- =====================================================

SELECT
    COUNT(*) AS orphan_return_rows
FROM transactions AS r
WHERE r.Qty < 0
  AND NOT EXISTS (
      SELECT 1
      FROM transactions AS s
      WHERE s.transaction_id = r.transaction_id
        AND s.Qty > 0
  );

-- =====================================================
-- Part A, TEST 6 : Query Explanation
-- 1. COUNT(*) counts the return rows that have no matching sale.
-- 2. FROM transactions AS r uses the transactions table
--    and gives the return rows the alias r.
-- 3. WHERE r.Qty < 0 selects rows representing returns.
-- 4. NOT EXISTS checks that no matching sale row can be found.
-- 5. The subquery searches the transactions table again,
--    using the alias s for possible sale rows.
-- 6. s.transaction_id = r.transaction_id requires the same
--    transaction ID for the sale and return.
-- 7. s.Qty > 0 requires the matching row to have a positive
--    quantity, indicating a sale under this project's rule.
-- Result: 2 return rows have no matching sale and should be reported.
-- =====================================================


-- =====================================================
-- Part A, TEST 7: RECONCILE GROSS SALES, RETURNS, AND NET SALES
-- Expected: net sales = gross sales + returns
-- =====================================================

SELECT
    ROUND(SUM(CASE
        WHEN Qty > 0 THEN total_amt
        ELSE 0
    END), 2) AS gross_sales,

    ROUND(SUM(CASE
        WHEN Qty < 0 THEN total_amt
        ELSE 0
    END), 2) AS returns,

    ROUND(SUM(total_amt), 2) AS net_sales,

    ROUND(
        SUM(total_amt) -
        SUM(CASE WHEN Qty > 0 THEN total_amt ELSE 0 END) -
        SUM(CASE WHEN Qty < 0 THEN total_amt ELSE 0 END),
        2
    ) AS reconciliation_difference
FROM transactions
WHERE total_amt IS NOT NULL;

-- =====================================================
-- Part A, TEST 7 : Query Explanation
-- 1. CASE WHEN Qty > 0 identifies sale rows and includes their
--    total_amt in gross sales. Other rows contribute 0.
-- 2. CASE WHEN Qty < 0 identifies return rows and includes their
--    total_amt in the returns total. Other rows contribute 0.
-- 3. SUM() adds the amounts for each calculation.
-- 4. ROUND(..., 2) rounds each total to two decimal places.
-- 5. SUM(total_amt) calculates net sales across all rows.
-- 6. reconciliation_difference subtracts gross sales and returns
--    from net sales to check whether the figures reconcile.
-- 7. WHERE total_amt IS NOT NULL excludes rows without an amount.
-- Result: 0.00 difference means the three totals reconcile.
-- =====================================================



-- =====================================================
-- PART B: STATISTICAL TEST DATA PREPARATION
-- Database: MySQL
-- Purpose: Prepare datasets for statistical tests in Python.
-- =====================================================

USE retail_store_analytics;


-- =====================================================
-- TEST 1: CHI-SQUARE TEST OF INDEPENDENCE
-- =====================================================
-- Purpose:
-- Compare product category distribution across different
-- store types.
--
-- Null Hypothesis (H0):
-- Product category distribution is independent of store type.
--
-- Alternative Hypothesis (H1):
-- Product category distribution is associated with store type.
--
-- The chi-square test will be performed in Python using
-- the contingency table generated by this query.
-- =====================================================

SELECT
    t.Store_type,
    p.prod_cat AS product_category,
    COUNT(*) AS transaction_count
FROM transactions AS t
INNER JOIN prod_cat_info AS p
    ON t.prod_cat_code = p.prod_cat_code
   AND t.prod_subcat_code = p.prod_sub_cat_code
GROUP BY
    t.Store_type,
    p.prod_cat
ORDER BY
    t.Store_type,
    p.prod_cat;


-- =====================================================
-- EXPLANATION OF TEST 1 QUERY
-- =====================================================
-- 1. The transactions table contains transaction records,
--    including the store type and product category codes.
--
-- 2. The prod_cat_info table provides the corresponding
--    product category names.
--
-- 3. INNER JOIN matches each transaction with its product
--    category using both the category code and subcategory
--    code. This ensures that the product mapping is correct.
--
-- 4. COUNT(*) counts the transactions for each combination
--    of store type and product category.
--
-- 5. GROUP BY creates one result row for each store-type
--    and product-category combination.
--
-- 6. ORDER BY arranges the output by store type and
--    product category for easier inspection.
--
-- Expected output:
-- A summary of transaction counts for each store type
-- and product category. These counts are exported or copied
-- into Python to construct a contingency table.
--
-- Statistical interpretation:
-- The chi-square test checks whether the distribution of
-- product categories differs across store types.
-- A p-value below 0.05 provides evidence against H0.
-- A p-value of 0.05 or higher means H0 is not rejected.
-- =====================================================



-- =====================================================
-- TEST 2: WELCH'S INDEPENDENT TWO-SAMPLE T-TEST
-- =====================================================
-- Purpose:
-- Compare positive transaction amounts associated with
-- male and female customers.
--
-- Null Hypothesis (H0):
-- The mean positive transaction amount is equal for
-- male and female customers.
--
-- Alternative Hypothesis (H1):
-- The mean positive transaction amount differs between
-- male and female customers.
--
-- Welch's t-test will be performed in Python.
-- =====================================================

SELECT
    c.gender,
    t.transaction_id,
    t.total_amt
FROM transactions AS t
INNER JOIN customer AS c
    ON t.cust_id = c.customer_id
WHERE c.gender IN ('M', 'F')
  AND t.total_amt > 0
ORDER BY
    c.gender,
    t.transaction_id;


-- =====================================================
-- EXPLANATION OF TEST 2 QUERY
-- =====================================================
-- 1. The transactions table contains transaction IDs,
--    customer IDs, and transaction amounts.
--
-- 2. INNER JOIN connects each transaction to the relevant
--    customer record using the customer ID.
--
-- 3. The condition c.gender IN ('M', 'F') includes only
--    customers whose recorded gender is M or F.
--
-- 4. The condition t.total_amt > 0 includes only positive
--    transaction amounts, excluding zero and negative
--    amounts such as recorded returns.
--
-- 5. The SELECT statement returns three columns:
--    gender, transaction_id, and total_amt.
--
-- 6. ORDER BY sorts the results by gender and transaction
--    ID, making the exported dataset easier to inspect.
--
-- Expected output:
-- One row per qualifying transaction, containing the
-- customer's gender and the positive transaction amount.
--
-- Data preparation:
-- Export the complete result to CSV and load it into Python.
-- Separate the positive transaction amounts into M and F
-- groups before performing Welch's independent two-sample
-- t-test.
--
-- Statistical interpretation:
-- Welch's t-test compares the two group means without
-- assuming equal population variances.
-- A p-value below 0.05 provides evidence against H0.
-- A p-value of 0.05 or higher means H0 is not rejected.
--
-- Limitation:
-- Multiple transactions can belong to the same customer.
-- Therefore, individual transactions may not be independent
-- observations. This should be considered when interpreting
-- the statistical result.
-- =====================================================


-- =====================================================
-- END OF PART B
-- =====================================================
