WITH CONTRATOSACTIVOS AS(
    SELECT DISTINCT ACT_ACCT_CD, EXTRACT(MONTH FROM FECHA_EXTRACCION) AS MES, MAX(FECHA_EXTRACCION) AS FECHAACTIVO
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD, MES
),
PLANACTIVOS AS(
      SELECT DISTINCT t.ACT_ACCT_CD, EXTRACT (MONTH FROM FECHA_EXTRACCION) AS MESPLAN
    , MAX(FECHA_EXTRACCION) AS FECHABASE,
    CASE
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "3P"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "2P - BB+TV"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - BB+VO"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - TV+VO"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NULL THEN "1P - BB"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "1P - TV"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "1P - VO"
    END AS PFLAG,
    CASE WHEN Max(C_CUST_AGE) <= 6 THEN "6M"
        WHEN Max(C_CUST_AGE) > 6 AND Max(C_CUST_AGE) <= 12 THEN "6M-1Y"
        WHEN Max(C_CUST_AGE) > 12 AND Max(C_CUST_AGE) <= 24 THEN "1Y-2Y"
        WHEN Max(C_CUST_AGE) > 24 THEN "2Y+"
        END AS TENURE
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D` t
    INNER JOIN CONTRATOSACTIVOS a ON t.ACT_ACCT_CD = a.ACT_ACCT_CD
    GROUP BY ACT_ACCT_CD, PFLAG, MESPLAN, FECHAACTIVO
    HAVING extract(YEAR FROM FECHABASE) = 2021 AND FECHABASE = FECHAACTIVO
)
SELECT DISTINCT MESPLAN, PFLAG
, TENURE, 
Count(DISTINCT ACT_ACCT_CD) AS NumActivos
FROM PLANACTIVOS
GROUP BY MESPLAN, PFLAG, TENURE
ORDER BY MESPLAN, TENURE ASC, PFLAG ASC
