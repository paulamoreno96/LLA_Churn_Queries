WITH 
CHURNMAX AS(
     SELECT DISTINCT ACT_ACCT_CD, MAX(CST_CHRN_DT) AS Maxfecha,
      CASE
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "3P"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "2P - BB+TV"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - BB+VO"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - TV+VO"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NULL THEN "1P - BB"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "1P - TV"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "1P - VO"
    END AS PFLAG
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
GROUP BY ACT_ACCT_CD, PFLAG
 HAVING EXTRACT (MONTH FROM MAX(CST_CHRN_DT)) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
CRUCECHURN AS
(
 SELECT DISTINCT c.ACT_ACCT_CD, c.Maxfecha,c.PFLAG, min(t.ACT_ACCT_INST_DT) as MinInst
 FROM CHURNMAX c INNER JOIN `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D` t
 ON c.ACT_ACCT_CD = t.ACT_ACCT_CD AND c.Maxfecha = t.CST_CHRN_DT
 GROUP BY c.ACT_ACCT_CD, c.Maxfecha, c.PFLAG
),

CHURNERSCRM AS(
    SELECT DISTINCT ACT_ACCT_CD, C.Maxfecha, Pflag,
    CASE WHEN DATE_DIFF( C.Maxfecha, c.MinInst, DAY)<=90 AND c.MinInst<C.Maxfecha THEN "<3M"
    WHEN DATE_DIFF(C.Maxfecha, c.MinInst, DAY)<=180 AND DATE_DIFF(C.Maxfecha, c.MinInst, DAY)>90 THEN "03-6M"
    WHEN DATE_DIFF(C.Maxfecha, c.MinInst, DAY)<=270 AND DATE_DIFF(C.Maxfecha, c.MinInst, DAY)>180 THEN "06-9M"
    WHEN DATE_DIFF(C.Maxfecha, c.MinInst, DAY)<=360 AND DATE_DIFF(C.Maxfecha, c.MinInst, DAY)>270 THEN "09-1A"
    WHEN DATE_DIFF(C.Maxfecha, c.MinInst, DAY)<=720 AND DATE_DIFF(C.Maxfecha, c.MinInst, DAY)>360 THEN "1-2 A"
    WHEN DATE_DIFF(C.Maxfecha, c.MinInst, DAY)<=1080 AND DATE_DIFF(C.Maxfecha, c.MinInst, DAY)>720 THEN "2-3 A"
    WHEN DATE_DIFF(C.Maxfecha, c.MinInst, DAY)<=1440 AND DATE_DIFF(C.Maxfecha, c.MinInst, DAY)>1080 THEN "3-4 A"
    WHEN DATE_DIFF(C.Maxfecha, c.MinInst, DAY)>1440 THEN "+4A" END AS TENURE,
    FROM CRUCECHURN c
    GROUP BY ACT_ACCT_CD, PFLAG, Tenure, c.maxFecha
)
SELECT DISTINCT EXTRACT (MONTH FROM Maxfecha) as MES, PFLAG
, TENURE, 
Count(DISTINCT ACT_ACCT_CD) AS NumChurners
FROM CHURNERSCRM
GROUP BY MES, PFLAG, TENURE
ORDER BY MES, TENURE ASC