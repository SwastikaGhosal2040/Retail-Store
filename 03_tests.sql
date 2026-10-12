-- Test 1: Deduplication Row Count Check (Expected: 23,040 rows)
SELECT COUNT(*) AS total_clean_rows FROM transactions;

-- Test 2: Orphan Customer Check (Expected: 0 rows)
SELECT t.cust_id 
FROM transactions t
LEFT JOIN customer c ON t.cust_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Test 3: Orphan Product Check (Two-column join, Expected: 0 rows)
SELECT t.transaction_id 
FROM transactions t
LEFT JOIN prod_cat_info p 
  ON t.prod_cat_code = p.prod_cat_code 
 AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat_code IS NULL;

-- Test 4: Tax Calculation Integrity Check (Expected: 0 invalid rows)
SELECT * 
FROM transactions 
WHERE ABS(tax - (0.105 * qty * rate)) > 0.01;

-- Test 5: Total Amount Integrity Check (Expected: 0 invalid rows)
SELECT * 
FROM transactions 
WHERE ABS(ABS(total_amt) - (ABS(qty * rate) + tax)) > 0.01;
