update ecommerce_raw
set country = case 
            WHEN country IN ('US', 'United States', 'USA') 
            THEN 'United States'
            ELSE country
END
DROP VIEW IF EXISTS DimGeography 
GO

CREATE VIEW DimGeography AS 
WITH normalized_data AS (
    SELECT 
        region,
        CASE 
            WHEN country IN ('US', 'United States', 'USA') THEN 'United States'
            ELSE country
        END AS country_normalized
    FROM  ecommerce_raw
    WHERE region IS NOT NULL
),


country as(  SELECT 
        ROW_NUMBER() OVER( ORDER BY country_normalized ) AS country_key,
        
        country_normalized as Country

    FROM  normalized_data
    GROUP BY country_normalized
)

select  ROW_NUMBER() OVER( ORDER BY country_normalized) AS region_key,
    nd.region, c.country,country_key
from country c
left join normalized_data nd on nd.country_normalized = c.Country
group by  nd.region, c.country,country_key,country_normalized;

GO


 UPDATE ecommerce_raw
    SET gross_margin_pct =  cast(REPLACE(gross_margin_pct,'%','') AS DECIMAL(10,2)),
    discount_pct =  cast(REPLACE(discount_pct,'%','') AS DECIMAL(10,2))
ALTER TABLE ecommerce_raw
alter COLUMN gross_margin_pct decimal(10,2)
ALTER TABLE ecommerce_raw
alter COLUMN discount_pct decimal(10,2)
GO
DROP VIEW IF EXISTS FactSales
GO
CREATE VIEW FactSales AS

   
     
    WITH dates_cleaned AS (
     SELECT 
        product_id, order_id, order_date,ship_date as ship,delivery_date as delivery,
        COALESCE(
            TRY_CAST(TRY_CONVERT(DATETIME, order_date, 101) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, order_date, 103) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, order_date, 105) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, order_date, 120) AS DATE)
        ) AS parsed_order_date,
        
        COALESCE(
            TRY_CAST(TRY_CONVERT(DATETIME, ship_date, 101) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, ship_date, 103) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, ship_date, 105) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, ship_date, 120) AS DATE)
        ) AS parsed_ship_date,
                COALESCE(
            TRY_CAST(TRY_CONVERT(DATETIME, delivery_date, 101) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, delivery_date, 103) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, delivery_date, 105) AS DATE),
            TRY_CAST(TRY_CONVERT(DATETIME, delivery_date, 120) AS DATE)
        ) AS parsed_delivery_date,
        order_date AS raw_order_date,
        ship_date AS raw_ship_date
    FROM ecommerce_raw
),

dates_normalized AS (
    SELECT 
        product_id, order_id, order_date,ship,delivery,
        CASE 
            WHEN YEAR(parsed_order_date) > YEAR(parsed_ship_date) 
            
            THEN DATEFROMPARTS(
                YEAR(parsed_ship_date),
                MONTH(parsed_order_date),
                day(parsed_order_date) 
                )
            ELSE parsed_order_date 
        END AS final_order_date,
        
        CASE 
            WHEN YEAR(parsed_ship_date) < YEAR(parsed_order_date) or
                year(parsed_order_date) > YEAR(parsed_delivery_date)
            
            THEN DATEFROMPARTS(
                YEAR(parsed_delivery_date),
                MONTH(parsed_ship_date),
                day(parsed_ship_date) 
                )
            ELSE parsed_ship_date end  AS final_ship_date,
        raw_order_date,
        raw_ship_date
    FROM dates_cleaned
)
   
      SELECT DISTINCT  r.product_id,r.order_id,
           nor.final_order_date AS order_date,
            nor.final_ship_date as ship_date,
            COALESCE(
            TRY_CAST(TRY_CONVERT(DATETIME,delivery_date,101) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,delivery_date,103) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,delivery_date,105) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,delivery_date,120) AS DATE)
            )AS delivery_date,
            customer_id,
            dg.region_key,
            CASE 
                WHEN sales_channel in('shop','Shopify' ) THEN 'Shopify'
                when sales_channel in ('AMZ','Amazon' )     THEN 'Amazon'
                ELSE sales_channel
                END AS sales_channel,
            
            sum(quantity) as quantity ,
            sum(unit_cogs) as unit_cogs,
            CASE 
                WHEN discount_pct > 1 THEN discount_pct / 100
                ELSE discount_pct
                END AS discount_pct,
            sum(gross_revenue) as gross_revenue ,
            sum(net_revenue) as net_revenue,
            sum(cogs_total) as cogs_total ,
            sum(gross_profit) as gross_profit,
            CASE 
                WHEN  gross_margin_pct > 1 THEN gross_margin_pct / 100
                ELSE gross_margin_pct
                END AS gross_margin_pct,
            sum(shipping_cost) as  shipping_cost ,
            
            CASE 
                WHEN lower(payment_method) IN('visa','mastercard','cc') THEN 'Credit Card'
                    ELSE payment_method
                    END AS payment_method,
            lower(payment_status) as payment_status,
            Case when nor.final_ship_date is null then 'Unfulfilled'
                when r.delivery_date is null then 'Unfulfilled'
                else 'Fulfilled'
                end as fulfillment_status,
            order_status,
            notes
        FROM ecommerce_raw r
        --LEFT JOIN DimGeography on ecommerce_raw.country = DimGeography.Country
        LEFT JOIN dates_normalized nor on r.product_id = nor.product_id
        AND  r.order_id = nor.order_id 
        AND r.order_date = nor.order_date 
        AND r.ship_date = nor.ship
        AND r.delivery_date = nor.delivery
        LEFT JOIN DimGeography dg on r.region = dg.region
        GROUP BY r.product_id,r.order_id,
           nor.final_order_date,
            nor.final_ship_date , r.delivery_date,r.customer_id,dg.region_key,
            r.sales_channel, fulfillment_status,
            order_status,gross_margin_pct,
            notes,r.discount_pct,
            r.payment_method,
            r.payment_status
GO


DROP VIEW IF EXISTS DimCustomer
GO
CREATE VIEW DimCustomer AS 

WITH unique_cust AS (
    SELECT customer_id,customer_name,customer_email,customer_segment,
        ROW_NUMBER() over(PARTITION BY customer_id ORDER BY customer_id) as num_cust
    from ecommerce_raw)


    SELECT customer_id,customer_name,customer_email,customer_segment
    from unique_cust
    where num_cust = 1
GO

DROP VIEW IF EXISTS DimProduct
GO
CREATE VIEW DimProduct AS 

WITH unique_products as (
    SELECT product_id, product_name, 
        COALESCE(subcategory,
            CASE
    
           
                WHEN lower(product_name) like '%cutlery%' THEN 'Cutlery'
                WHEN lower(product_name) like '%desk%' THEN 'Desks'
                WHEN lower(product_name) like '%shelves%' THEN 'Shelves'
                WHEN lower(product_name) like '%boxes%' THEN 'Boxes'
                WHEN lower(product_name) like '%baskets%' THEN 'Baskets'
                WHEN lower(product_name) like '%patio%' THEN 'Patio'
                WHEN lower(product_name) like '%lighting%' THEN 'Lighting'
                WHEN lower(product_name) like '%bedding%' THEN 'Bedding'
                WHEN lower(product_name) like '%decor%' THEN 'Decor'
                WHEN lower(product_name) like '%cookware%' THEN 'Cookware'
                WHEN lower(product_name) like '%utensils%' THEN 'Utensils'
                WHEN lower(product_name) like '%chairs%' THEN 'Chairs'
                WHEN lower(product_name) like '%chairs%' THEN 'Chairs'
                WHEN lower(product_name) like '%gardening%' THEN 'Gardening'
                WHEN lower(product_name) like '%accessories%' THEN 'Accessories'
            ELSE NULL
        END ) AS subcategory,
        REPLACE(category,'Storage & Organization','Storage') AS category ,
        reorder_point,supplier_id,
        ROW_NUMBER() over(partition by product_id order by product_id) as num_fila 

    from ecommerce_raw)
    

    SELECT  product_id, product_name,subcategory, category,reorder_point,supplier_id
    from unique_products
    WHERE num_fila = 1;
GO


DROP VIEW IF EXISTS FactInventory
GO
CREATE VIEW FactInventory AS 


    SELECT  product_id, inventory_on_hand,unit_price,
        days_in_stock, supplier_lead_time_days,warehouse_id,fulfillment_status,           
         COALESCE(
            TRY_CAST(TRY_CONVERT(DATETIME,ship_date,101) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,ship_date,103) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,ship_date,105) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,ship_date,120) AS DATE)
            )AS movement_day 
        from ecommerce_raw
GO



DROP VIEW IF EXISTS FactReturns
GO
CREATE VIEW FactReturns AS 

    WITH returns_processed AS (
    SELECT DISTINCT order_id,
        COALESCE(
            TRY_CAST(TRY_CONVERT(DATETIME,return_date,101) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,return_date,103) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,return_date,105) AS DATE),
                TRY_CAST(TRY_CONVERT(DATETIME,return_date,120) AS DATE)
            )AS return_date,
            
        return_reason,refund_amount,
        CASE 
            WHEN return_flag IS NULL THEN 0
            WHEN lower(return_flag) IN ('y','true','yes') THEN 1
            WHEN lower(return_flag) IN ('n','false','no') THEN 0
            ELSE return_flag
            END as return_flag,product_id,region_key
            
    from ecommerce_raw
    LEFT JOIN DimGeography on ecommerce_raw.country = DimGeography.Country

)
    select order_id,return_date,return_reason,sum(refund_amount) AS refund_amount,product_id,region_key


        FROM returns_processed
        WHERE return_flag !=0
        GROUP BY order_id,return_date,return_reason,product_id,region_key;
GO
        






