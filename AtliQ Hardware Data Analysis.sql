
## All the tables are here
## created dim_date table with fiscal year by applying formula
## created fiscal year in fact_sales_monthly to increase the performance
select * from dim_date;
select * from dim_customer;
select * from dim_product;
select * from fact_sales_monthly;
select * from fact_gross_price;
select * from fact_pre_invoice_deductions;
select * from fact_post_invoice_deductions;

## Takes some necessary columns and join all the tables together
## Calculated Gross Price Total
select 
  s.date, 
  s.fiscal_year, 
  c.market, 
  s.product_code, 
  p.product, 
  p.variant, 
  s.customer_code, 
  s.sold_quantity, 
  g.gross_price, 
  round(
    (g.gross_price * s.sold_quantity), 
    0
  ) as gross_price_total, 
  pre.pre_invoice_discount_pct 
from 
  fact_sales_monthly s 
  join dim_customer c on s.customer_code = c.customer_code 
  join dim_product p on s.product_code = p.product_code 
  join fact_gross_price g on s.product_code = g.product_code 
  and s.fiscal_year = g.fiscal_year 
  join fact_pre_invoice_deductions pre on s.customer_code = pre.customer_code 
  and s.fiscal_year = pre.fiscal_year;



## Created SQL Views named pre_invoice_discounts
## Calculated Net Invoice Sales from created views
## Join another table with views
## Finally calculated Total Post Invoice Discounts for further calculation
select 
  *, 
  (
    gross_price_total - gross_price_total * pre_invoice_discount_pct
  ) as net_invoice_sales, 
  (
    po.discounts_pct + po.other_deductions_pct
  ) as post_invoice_discount_pct 
from 
  pre_invoice_discounts pd 
  join fact_post_invoice_deductions po on pd.customer_code = po.customer_code 
  and pd.product_code = po.product_code 
  and pd.date = po.date;
  

## Created SQL Views named post_invoice_discounts
## Calculated Total Net Sales from views
select 
  *, 
  round(
    (
      net_invoice_sales - net_invoice_sales * post_invoice_discount_pct
    ), 
    0
  ) as net_sales 
from 
  post_invoice_discounts;


## Created SQL Views named net_sales
## Retrieve Top N Market by Net Sales
## Created Stored Procedure to make things Dynamic
with cte as (
  select 
    market, 
    round(
      sum(net_sales) / 1000000, 
      2
    ) as net_sales_mlns, 
    dense_rank() over(
      order by 
        sum(net_sales) desc
    ) as rn 
  from 
    net_sales 
  where 
    fiscal_year = in_fiscal_year # Take Financial Year as Input
  group by 
    fiscal_year, 
    market
) 
select 
  market, 
  net_sales_mlns 
from 
  cte 
where 
  rn <= in_top_n; # Take Top N number as Input


## Retrieve Top N Product by Net Sales
## Created Stored Procedure to make things Dynamic
with cte as (
  select 
    product, 
    round(
      sum(net_sales) / 1000000, 
      2
    ) as net_sales_mlns, 
    dense_rank() over(
      order by 
        sum(net_sales) desc
    ) as rn 
  from 
    net_sales 
  where 
    fiscal_year = in_fiscal_year # Take Financial Year as Input
  group by 
    fiscal_year, 
    product
) 
select 
  product, 
  net_sales_mlns 
from 
  cte 
where 
  rn <= in_top_n; # Take op N number as Input

## Retrieve Top N Customer by Net Sales
## Created Stored Procedure to make things Dynamic
with cte as (
  select 
    customer, 
    round(
      sum(net_sales) / 1000000, 
      2
    ) as net_sales_mlns, 
    dense_rank() over(
      order by 
        sum(net_sales) desc
    ) as rn 
  from 
    net_sales 
  where 
    fiscal_year = in_fiscal_year # Take Financial Year as Input
  group by 
    fiscal_year, 
    customer
) 
select 
  customer, 
  net_sales_mlns 
from 
  cte 
where 
  rn <= in_top_n; # Take Top N number as Input
  
  