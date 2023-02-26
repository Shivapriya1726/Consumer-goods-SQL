-- question 1

select distinct market from dim_customer
where customer = "Atliq Exclusive" and region = "APAC";

-- question 2

with CTE as (select count(distinct (case when fact_sales_monthly.fiscal_year = 2020 then dim_product.product_code end )) as unique_products_2020, 
count(distinct (case when fact_sales_monthly.fiscal_year = 2021 then dim_product.product_code end )) as unique_products_2021
from dim_product 
join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code) 
select unique_products_2020, unique_products_2021 ,concat( ROUND(100.0*(unique_products_2021 - unique_products_2020) / unique_products_2020 ,2) , '%' ) as percentage_chg
from CTE;

-- question 3

select segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by count(distinct product_code) desc;

-- question 4


with CTE as (select dim_product.segment, count(distinct case when  fact_sales_monthly.fiscal_year = 2020 then dim_product.product_code end) as product_count_2020 , 
count(distinct case when fact_sales_monthly.fiscal_year = 2021 then dim_product.product_code end) as product_count_2021
from dim_product
join fact_sales_monthly on dim_product.product_code = fact_sales_monthly.product_code
group by segment)
select * , (product_count_2021 - product_count_2020 ) as difference
from CTE
order by difference desc;

-- question 5

WITH products_cost AS (
  SELECT 
    product_code, 
    AVG(manufacturing_cost) AS manufacturing_cost
  FROM fact_manufacturing_cost
  GROUP BY product_code
)
SELECT 
  dim_product.product,
  products_cost.product_code, 
  products_cost.manufacturing_cost
FROM (
  SELECT 
    product_code, 
    manufacturing_cost, 
    ROW_NUMBER() OVER (ORDER BY manufacturing_cost DESC) AS rank_desc,
    ROW_NUMBER() OVER (ORDER BY manufacturing_cost ASC) AS rank_asc
  FROM products_cost
) products_cost
JOIN dim_product ON products_cost.product_code = dim_product.product_code
WHERE rank_desc = 1 OR rank_asc = 1
;


-- question 6
SELECT dim_customer.customer_code, dim_customer.customer, round(AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct), 3) as average_discount_percentage
FROM dim_customer 
JOIN fact_pre_invoice_deductions ON dim_customer.customer_code = fact_pre_invoice_deductions.customer_code
WHERE dim_customer.market = 'India' AND  fiscal_year = 2021
GROUP BY dim_customer.customer_code, dim_customer.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;


-- question 7

SELECT 
  YEAR(fact_sales_monthly.date) AS year, 
  MONTH(fact_sales_monthly.date) AS month,
  SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price) AS gross_sales_amount
FROM dim_customer
JOIN fact_sales_monthly ON dim_customer.customer_code = fact_sales_monthly.customer_code
JOIN fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
WHERE dim_customer.customer = 'Atliq Exclusive'
GROUP BY  YEAR(fact_sales_monthly.date), MONTH(fact_sales_monthly.date);

-- Question 8


select quarter(fact_sales_monthly.date) as quarter ,sum( fact_sales_monthly.sold_quantity) as total_sold_quantity
from fact_sales_monthly
where year(fact_sales_monthly.date) = 2020
group by quarter
order by total_sold_quantity desc;

-- question 9

WITH sales_by_channel AS (
  SELECT 
    dim_customer.channel, 
    round(SUM(fact_sales_monthly.sold_quantity * fact_gross_price.gross_price),2) AS gross_sales_mln 
  FROM dim_customer
  JOIN fact_sales_monthly ON dim_customer.customer_code = fact_sales_monthly.customer_code
  JOIN fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
  WHERE YEAR(fact_sales_monthly.date) = 2021
  GROUP BY dim_customer.channel
), 
total_sales AS (
  SELECT SUM(gross_sales_mln) AS total_sales_mln
  FROM sales_by_channel
)
SELECT 
  sales_by_channel.channel, 
  sales_by_channel.gross_sales_mln, 
  round( sales_by_channel.gross_sales_mln / total_sales.total_sales_mln * 100 , 2) AS percentage
FROM sales_by_channel
JOIN total_sales ON 1 = 1
ORDER BY sales_by_channel.gross_sales_mln DESC;

-- question 10


WITH products_by_division AS (
  SELECT 
    dim_product.division, 
     dim_product.product,
    fact_sales_monthly.product_code, 
    SUM(fact_sales_monthly.sold_quantity) AS total_sold_quantity
  FROM dim_product
  JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
  WHERE YEAR(fact_sales_monthly.date) = 2021
  GROUP BY dim_product.division, dim_product.product ,fact_sales_monthly.product_code
), 
products_by_division_ranked AS (
  SELECT 
    products_by_division.*, 
    ROW_NUMBER() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
  FROM products_by_division
)
SELECT 
  products_by_division_ranked.division, 
  products_by_division_ranked.product_code, 
  products_by_division_ranked.product,
  products_by_division_ranked.total_sold_quantity, 
  products_by_division_ranked.rank_order
FROM products_by_division_ranked
WHERE products_by_division_ranked.rank_order <= 3
ORDER BY products_by_division_ranked.division, products_by_division_ranked.rank_order;

