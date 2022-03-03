WITH SELECTED_MONTHS AS (
SELECT DISTINCT DATE_TRUNC(FECHA_EXTRACCION, MONTH) AS MONTH
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
WHERE DATE_TRUNC(FECHA_EXTRACCION, MONTH) IN ('2021-05-01','2021-06-01','2021-07-01')
)
, MONTH_ORDER AS (
SELECT MONTH, ROW_NUMBER() OVER (ORDER BY MONTH) AS MONTH_ORDER_ROW
FROM SELECTED_MONTHS
)
, CHURN_FILTER AS (
SELECT DISTINCT ACT_ACCT_CD, DATE(DATE_TRUNC(MAX(CST_CHRN_DT), MONTH)) AS CHURN_DATE
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
GROUP BY ACT_ACCT_CD
HAVING EXTRACT (MONTH FROM CHURN_DATE) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
)
, CHURN_MONTH_FILTER AS (
SELECT *
FROM CHURN_FILTER CF
WHERE CF.CHURN_DATE BETWEEN ((SELECT MAX(MONTH) FROM MONTH_ORDER)) AND DATE_ADD((SELECT MAX(MONTH) FROM MONTH_ORDER), INTERVAL 3 MONTH)
)
, LAST_VALS AS (
SELECT DISTINCT MO.MONTH
    , MO.MONTH_ORDER_ROW
    , CRM.PD_TV_PROD_CD
    , CRM.ACT_ACCT_CD AS CST_CUST_ID
    , FM.CHURN_DATE
    , LAST_VALUE(CRM.TV_FI_TOT_MRC_AMT) OVER (PARTITION BY CRM.CST_CUST_ID, DATE_TRUNC(CRM.FECHA_EXTRACCION, MONTH)  ORDER BY CRM.FECHA_EXTRACCION) LAST_MRC_MONTH
    , LAST_VALUE(CRM.TV_FI_TOT_MRC_AMT_DESC) OVER (PARTITION BY CRM.CST_CUST_ID, DATE_TRUNC(CRM.FECHA_EXTRACCION, MONTH) ORDER BY CRM.FECHA_EXTRACCION) LAST_MRC_DESC_MONTH
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D` CRM
    INNER JOIN MONTH_ORDER MO
        ON DATE_TRUNC(CRM.FECHA_EXTRACCION, MONTH) = MO.MONTH
    INNER JOIN CHURN_MONTH_FILTER FM
        ON CRM.ACT_ACCT_CD = FM.ACT_ACCT_CD
WHERE CRM.PD_TV_PROD_CD IS NOT NULL
)
, LAST_MRC AS (
SELECT MONTH
    , MONTH_ORDER_ROW
    , PD_TV_PROD_CD
    , CST_CUST_ID
    , CHURN_DATE
    , LAST_MRC_MONTH - LAST_MRC_DESC_MONTH AS LAST_MRC
FROM LAST_VALS LV
)
, PIVOT_VALS AS (
SELECT PD_TV_PROD_CD AS PRODUCT_NAME
    , CST_CUST_ID
    , CHURN_DATE
    , SUM(CASE WHEN MONTH_ORDER_ROW = 1 THEN LAST_MRC END) AS MRC_MONTH_1
    , SUM(CASE WHEN MONTH_ORDER_ROW = 2 THEN LAST_MRC END) AS MRC_MONTH_2
    , SUM(CASE WHEN MONTH_ORDER_ROW = 3 THEN LAST_MRC END) AS MRC_MONTH_3 
FROM LAST_MRC LM
GROUP BY 1,2,3
)
SELECT PV.*
    , CASE 
        WHEN MRC_MONTH_1 IS NULL OR MRC_MONTH_2 IS NULL THEN NULL
        WHEN MRC_MONTH_1 > MRC_MONTH_2 THEN 'WENT DOWN'
        WHEN MRC_MONTH_1 = MRC_MONTH_2  THEN 'SAME'
        ELSE 'WENT UP'
    END AS MONTH2_VS_MONTH1
    , MRC_MONTH_2/NULLIF(MRC_MONTH_1,0) - 1 AS CHANGE_PERC_2_VS_1 
    , CASE 
        WHEN MRC_MONTH_2 IS NULL OR MRC_MONTH_3 IS NULL THEN NULL
        WHEN MRC_MONTH_2 > MRC_MONTH_3 THEN 'WENT DOWN'
        WHEN MRC_MONTH_2 = MRC_MONTH_3  THEN 'SAME'
        ELSE 'WENT UP'
    END AS MONTH3_VS_MONTH2
    , MRC_MONTH_3/NULLIF(MRC_MONTH_2,0) - 1 AS CHANGE_PERC_3_VS_2
FROM PIVOT_VALS PV
;
