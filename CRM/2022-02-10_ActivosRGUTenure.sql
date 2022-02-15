WITH RGUSACTIVOSBBMES AS(
    SELECT DISTINCT ACT_ACCT_CD, EXTRACT(MONTH FROM FECHA_EXTRACCION) AS MES, MAX(FECHA_EXTRACCION) AS FECHABASE
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    --WHERE PD_BB_PROD_ID IS NOT NULL
    --WHERE PD_TV_PROD_ID IS NOT NULL
    WHERE PD_VO_PROD_ID IS NOT NULL
    GROUP BY ACT_ACCT_CD, MES),
TENUREACTIVOS AS(
 SELECT DISTINCT EXTRACT(MONTH FROM t.FECHA_EXTRACCION) AS MES, t.ACT_ACCT_CD,
  CASE WHEN C_CUST_AGE <= 3 THEN "<3M"
        WHEN C_CUST_AGE > 3 AND C_CUST_AGE <= 6 THEN "03-6M"
        WHEN C_CUST_AGE > 6 AND C_CUST_AGE <= 9 THEN "06-9M"
        WHEN C_CUST_AGE >9 AND C_CUST_AGE <= 12 THEN "09-1A"
        WHEN C_CUST_AGE >12 AND C_CUST_AGE <= 24 THEN "1-2 A"
        WHEN C_CUST_AGE >24 AND C_CUST_AGE <= 36 THEN "2-3 A"
        WHEN C_CUST_AGE > 26 AND C_CUST_AGE <=48 THEN "3-4 A"
    ELSE "+4A" END AS TENURE
     FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D` t INNER JOIN 
    RGUSACTIVOSBBMES r ON t.ACT_ACCT_CD = r.ACT_ACCT_CD AND r.MES = extract (month from t.FECHA_EXTRACCION) and r.FECHABASE = t.FECHA_EXTRACCION
     --WHERE PD_BB_PROD_ID IS NOT NULL
    --WHERE PD_TV_PROD_ID IS NOT NULL
    WHERE PD_VO_PROD_ID IS NOT NULL
GROUP BY t.ACT_ACCT_CD, MES, TENURE)
SELECT t.MES, t.TENURE, COUNT(DISTINCT t.ACT_ACCT_CD)
FROM TENUREACTIVOS t 
GROUP BY MES, TENURE
ORDER BY MES, TENURE