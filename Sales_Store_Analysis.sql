create table Sales_sql_report(
transaction_id varchar(100),
 customer_id varchar(100),
 customer_name varchar(100),
 customer_age int,
 gender	varchar(10), 
 product_id varchar(20), 
 product_name varchar(50), 
 product_category varchar(50), 
 quantiy int, prce int,	
 payment_mode varchar(20), 
 purchase_date	date,
 time_of_purchase time,
 status varchar(20)
 );

 select * from sales_sql_report;

set DATEFORMAT dmy
bulk insert sales_sql_report
from "C:\Users\chinn\Downloads\archive (6)\sales.csv"
with (
firstrow = 2,
fieldterminator = ',',
rowterminator = '\n'
);

SELECT * into sales from sales_sql_report


select * from sales

--Data cleaning

--step 1 : To check for duplicate

select TRANSACTION_ID, count(*)
from sales
group by transaction_id
having count(transaction_id)>1

TXN240646
TXN342128
TXN626832
TXN745076
TXN832908
TXN855235
TXN981773


with cte as(
SELECT *,
		ROW_NUMBER() over (partition by transaction_id order by transaction_id) as row_num
from sales 
)
--DELETE FROM CTE
--WHERE ROW_NUM = 2;
select * from cte
where transaction_id in ('TXN240646',
'TXN342128',
'TXN626832',
'TXN745076',
'TXN832908',
'TXN855235',
'TXN981773')

-- step2 = Corrections of error headers

exec sp_rename'sales.quantiy','quantity','COLUMN'

exec sp_rename'sales.price','price','column'


--step3 = to check datatype

select column_name, data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'sales'


-- step4 = to check Null values

DECLARE @SQL NVARCHAR(MAX);

SELECT @SQL = STRING_AGG(
    'SELECT ''' + COLUMN_NAME + ''' AS column_name, COUNT(*) AS null_count ' +
    'FROM ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ' ' +
    'WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
    ' UNION ALL '
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

-- Execute the dynamic SQL
EXEC sp_executesql @SQL;


--treating null values

select * from sales 
where transaction_id is null
or customer_id is null
or customer_name is null
or customer_age is null
or gender is null
or product_id is null
or product_name is null
or product_category is null	
or quantity is null	
or price is null
or payment_mode is null 
or purchase_date is null
or time_of_purchase is null	
or status is null


delete from sales 
where transaction_id is null


select * from sales 
where customer_name = 'ehsaan ram'

update sales 
set customer_id = 'CUST9494'
where transaction_id = 'TXN977900'

select * from sales 
where customer_id = 'CUST1003'


update sales 
set customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
where transaction_id = 'TXN432798'


select * from sales 
where customer_name = 'Damini Raju'

update sales 
set customer_id = 'CUST1401'
where transaction_id = 'TXN985663'


--step5 Data cleaning

--check Distinct values

select distinct gender from sales 

update sales 
set gender = 'M'
where gender  = 'Male'


update sales 
set gender = 'F'
where gender = 'Female'


select distinct payment_mode from sales


update sales 
set payment_mode = 'Credit Card'
where payment_mode = 'CC'


--Data Analysis 

--  1)What are the top 5 most selling products by quantity?

select top 5 product_name, sum(quantity) as total_quatity
from sales
group by product_name
order by total_quatity desc;
--Business problem: we dont know which products are most in demand. 

--Business impact: helps prioritise stocks and boost sale through targeted promotion. 


--  2)Which products are most frequently cancelled ?

select product_name, count(status) as cancelled from sales
where status = 'cancelled'
group by product_name 
order by  cancelled desc

-- Business problem: frequent cancellations affect revenue and customer trust. 

-- Business impact: identify poor-performing products to improve quality are removed from catalog.

--  3)What time of the day has the highest number of purchases ?

Select 
	case 
		when datepart(hour,time_of_purchase) between 0 and 5 then 'night'
		when DATEPART(hour,time_of_purchase) between 6 and 11 then 'morning'
		when DATEPART(hour,time_of_purchase) between 12 and 17 then 'afternoon'
		when DATEPART(hour,time_of_purchase) between 18 and 23 then 'evening'
	end as time_of_day,
	count(*) as total_order
	from sales 
	group by
		case 
		when datepart(hour,time_of_purchase) between 0 and 5 then 'night'
		when DATEPART(hour,time_of_purchase) between 6 and 11 then 'morning'
		when DATEPART(hour,time_of_purchase) between 12 and 17 then 'afternoon'
		when DATEPART(hour,time_of_purchase) between 18 and 23 then 'evening'
	end 
	order by total_order desc


--	Business problem: finding peak times.

-- Business impact :optimize staffing, promotion and server loads

--  4)Who are the top five highest spending customers ?

select top 5 customer_name, 
	format(sum(quantity*price),'c0', 'en-in') as total_spend from sales
group by customer_name
order by sum(quantity*price) desc

--Business problem: identify VIP customers
--Business impact: Personalised offers, loyalty reward, and retention   

--  5)Which product categories generate the highest revenue ?

select product_category, format(sum(price),'c0','en-in') total_sale from sales
group by product_category
order by sum(price) desc

--Business problem : Identify top performing product categories  
--Business impact: refund product strategy, supply chain and promotions.
--allowing the business to invest more in high-margin or high-demand categories. 


--  6)What is the Return/cancellation rate per product category ?

--cancellation
select product_category, 
format(count(case when status= 'cancelled' then 1 end)*100/count(*),'n0')+' %' as cancel_percentage from sales
group by product_category
order by cancel_percentage desc

--return
select product_category, 
format(count(case when status= 'returned' then 1 end)*100/count(*),'n0')+' %' as return_percentage from sales
group by product_category
order by return_percentage desc




--  7)What is the most preferred payment mode ?

select payment_mode, count(payment_mode) as no_of_times_used from sales 
group by payment_mode
order by count(payment_mode)  desc

--business problem: know which payment option customer prefer
--business impact : streamline payment processing, prioritize popular mode.

--  8)How does age group affect purchasing behaviour ?

select min(customer_age)as min_age , max(customer_age) as max_age from sales 

select
	case 
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 45 then '36-50'
		else '50+'
	End as cust_age,
	format(sum(quantity*price), 'c0', 'en-in') as total_purchase
	from sales
group by
	case 
		when customer_age between 18 and 25 then '18-25'	
		when customer_age between 26 and 35 then '26-35'
		when customer_age between 36 and 45 then '36-50'
		else '50+'
	End
order by sum(quantity*price) desc
		

--businness problem: understand customer demographics.
--business impact : targeted marketing product recommendations by ag group,


--  9)Whats the monthly sales trend ?
select min(purchase_date) as starting_date , max(purchase_date) as last_date from sales


--method-1

select format(purchase_date, 'yyyy-MM') as month_year,
format(sum(quantity*price),'c0','en-in') as total_sale,
sum(quantity) as total_quantity
from sales
group by format(purchase_date, 'yyyy-MM')

--Method-2

select 
	year(purchase_date) as year,
	month(purchase_date) as month,
	format(sum(quantity*price),'c0','en-in') as total_sale,
	sum(quantity) as total_quantity
	from sales 
	group by year(purchase_date), month(purchase_date)
	order by year , month

--Business problem:sales fluctuations go unnoticed.
--Business impact: plan inventory and marketing according to  seasonal trends.

--  10)Are certain genders buying more specific product categories /


--method 1 
select gender, product_category, count(product_category) as total_purchase
from sales 
group by gender, product_category
order by gender;

--method 2

select * 
from (
select gender, product_category from sales) as source_data
pivot( count(gender) for gender in ([M], [F])) as pivot_table 
order by product_category;
 --problem statement: gender base product reference
 --problem impact: personalized ads, gender_focused campaigns

select * from sales 
