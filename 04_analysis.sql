-- Q1: Total transaction rows and return count
SELECT 
    COUNT(*) AS total_transactions,
    SUM(is_return) AS return_transactions
FROM transactions;

-- Q2: Time range covered by dataset
SELECT 
    MIN(tran_date) AS start_date, 
    MAX(tran_date) AS end_date
FROM transactions;

-- Q3: Category for subcategory "DIY"
SELECT prod_cat 
FROM prod_cat_info 
WHERE prod_subcat = 'DIY';

-- Q4: Most used store type channel
SELECT store_type, COUNT(*) AS total_txns
FROM transactions
GROUP BY store_type
ORDER BY total_txns DESC;

-- Q5: Gender distribution
SELECT COALESCE(gender, 'Unknown') AS gender, COUNT(*) AS customer_count
FROM customer
GROUP BY gender;

-- Q6: Subcategories listed under Books
SELECT prod_subcat 
FROM prod_cat_info 
WHERE prod_cat = 'Books';

-- Q7: Combined net revenue from Electronics and Books
SELECT SUM(t.total_amt) AS net_revenue
FROM transactions t
JOIN prod_cat_info p 
  ON t.prod_cat_code = p.prod_cat_code 
 AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat IN ('Electronics', 'Books');

-- Q8: Customers with >10 non-return purchase transactions
SELECT cust_id, COUNT(*) AS purchase_count
FROM transactions
WHERE is_return = 0
GROUP BY cust_id
HAVING COUNT(*) > 10;

-- Q9: Top spending customer per city (Window Function)
WITH CitySpend AS (
    SELECT 
        c.city_code, 
        c.customer_id, 
        SUM(t.total_amt) AS net_spend,
        RANK() OVER (PARTITION BY c.city_code ORDER BY SUM(t.total_amt) DESC) AS rnk
    FROM transactions t
    JOIN customer c ON t.cust_id = c.customer_id
    WHERE c.city_code IS NOT NULL
    GROUP BY c.city_code, c.customer_id
)
SELECT city_code, customer_id, net_spend
FROM CitySpend
WHERE rnk = 1;
