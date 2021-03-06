WITH RGUSACTIVOSMES AS(
    SELECT DISTINCT ACT_ACCT_CD, EXTRACT(MONTH FROM FECHA_EXTRACCION) AS MES, MAX(FECHA_EXTRACCION) AS FECHABASE
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    --WHERE PD_BB_PROD_ID IS NOT NULL
    --WHERE PD_TV_PROD_ID IS NOT NULL
    WHERE PD_VO_PROD_ID IS NOT NULL
    GROUP BY ACT_ACCT_CD, MES),
TENUREACTIVOS AS(
 SELECT DISTINCT EXTRACT(MONTH FROM t.FECHA_EXTRACCION) AS MES, t.ACT_ACCT_CD,
  CASE WHEN Max(C_CUST_AGE) <= 6 THEN "6M"
        WHEN Max(C_CUST_AGE) > 6 AND Max(C_CUST_AGE) <= 12 THEN "6M-1Y"
        WHEN Max(C_CUST_AGE) > 12 AND Max(C_CUST_AGE) <= 24 THEN "1Y-2Y"
        WHEN Max(C_CUST_AGE) > 24 THEN "2Y+"
        END AS TENURE
     FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D` t INNER JOIN 
    RGUSACTIVOSMES r ON t.ACT_ACCT_CD = r.ACT_ACCT_CD AND r.MES = extract (month from t.FECHA_EXTRACCION) and r.FECHABASE = t.FECHA_EXTRACCION
     --WHERE PD_BB_PROD_ID IS NOT NULL
    --WHERE PD_TV_PROD_ID IS NOT NULL
    WHERE PD_VO_PROD_ID IS NOT NULL
GROUP BY t.ACT_ACCT_CD, MES)
SELECT t.MES, t.TENURE, COUNT(DISTINCT t.ACT_ACCT_CD)
FROM TENUREACTIVOS t 
GROUP BY MES, TENURE
ORDER BY MES, TENURE
