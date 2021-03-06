WITH ACTIVOSPLAN AS(
 SELECT DISTINCT ACT_ACCT_CD, FECHA_EXTRACCION AS FECHA,
    CASE
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "3P"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "2P - BB+TV"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - BB+VO"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - TV+VO"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NULL THEN "1P - BB"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "1P - TV"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "1P - VO"
    END AS PFLAG,
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
GROUP BY ACT_ACCT_CD, PFLAG, FECHA),
CRUCEACTIVOS AS(
    SELECT DISTINCT a.ACT_ACCT_CD, FECHA, PFLAG,  min(date(ACT_ACCT_INST_DT)) as MinInst
    FROM ACTIVOSPLAN a INNER JOIN `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D` t
    ON a.ACT_ACCT_CD = t.ACT_ACCT_CD AND a.FECHA = t.FECHA_EXTRACCION
    GROUP BY ACT_ACCT_CD, FECHA, PFLAG
),
TENUREACTIVOS AS(
    SELECT DISTINCT ACT_ACCT_CD, FECHA,PFLAG,
    CASE WHEN DATE_DIFF(FECHA,MinInst, DAY)<=90 AND MinInst < FECHA THEN "<3M"
    WHEN DATE_DIFF(FECHA,MinInst, DAY)<=180 AND DATE_DIFF(FECHA,MinInst, DAY)>90 THEN "03-6M"
    WHEN DATE_DIFF(FECHA,MinInst, DAY)<=270 AND DATE_DIFF(FECHA,MinInst, DAY)>180 THEN "06-9M"
    WHEN DATE_DIFF(FECHA,MinInst, DAY)<=360 AND DATE_DIFF(FECHA,MinInst, DAY)>270 THEN "09-1A"
    WHEN DATE_DIFF(FECHA,MinInst, DAY)<=720 AND DATE_DIFF(FECHA,MinInst, DAY)>360 THEN "1-2 A"
    WHEN DATE_DIFF(FECHA,MinInst, DAY)<=1080 AND DATE_DIFF(FECHA,MinInst, DAY)>720 THEN "2-3 A"
    WHEN DATE_DIFF(FECHA,MinInst, DAY)<=1440 AND DATE_DIFF(FECHA,MinInst, DAY)>1080 THEN "3-4 A"
    WHEN DATE_DIFF(FECHA,MinInst, DAY)>1440 THEN "+4A" END AS TENURE
    FROM CRUCEACTIVOS
)
SELECT EXTRACT (MONTH FROM FECHA)AS MES, PFLAG, TENURE, COUNT (DISTINCT ACT_ACCT_CD) as reg
FROM TENUREACTIVOS
GROUP BY MES, PFLAG, TENURE
ORDER BY MES, PFLAG, TENURE
