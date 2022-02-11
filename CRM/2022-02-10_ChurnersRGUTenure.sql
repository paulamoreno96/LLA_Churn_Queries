WITH 
CHURNERS AS(
     SELECT DISTINCT ACT_ACCT_CD, MAX(CST_CHRN_DT) AS Maxfecha,
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    --  WHERE PD_BB_PROD_ID IS NOT NULL
    -- WHERE PD_TV_PROD_ID IS NOT NULL
    WHERE PD_VO_PROD_ID IS NOT NULL
GROUP BY ACT_ACCT_CD
 HAVING EXTRACT (MONTH FROM MAX(CST_CHRN_DT)) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
CRUCECHURN AS
(
 SELECT DISTINCT c.ACT_ACCT_CD, c.Maxfecha, min(date(t.ACT_ACCT_INST_DT)) as MinInst
 FROM CHURNERS c INNER JOIN `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D` t
 ON c.ACT_ACCT_CD = t.ACT_ACCT_CD AND c.Maxfecha = t.CST_CHRN_DT
 GROUP BY c.ACT_ACCT_CD, c.Maxfecha
),
TENURE AS(
     SELECT DISTINCT ACT_ACCT_CD, c.Maxfecha,
    CASE WHEN DATE_DIFF( c.Maxfecha, c.MinInst, DAY)<=90 AND c.MinInst<c.Maxfecha THEN "<3M"
    WHEN DATE_DIFF(c.Maxfecha, c.MinInst, DAY)<=180 AND DATE_DIFF(c.Maxfecha, c.MinInst, DAY)>90 THEN "03-6M"
    WHEN DATE_DIFF(c.Maxfecha, c.MinInst, DAY)<=270 AND DATE_DIFF(c.Maxfecha, c.MinInst, DAY)>180 THEN "06-9M"
    WHEN DATE_DIFF(c.Maxfecha, c.MinInst, DAY)<=360 AND DATE_DIFF(c.Maxfecha, c.MinInst, DAY)>270 THEN "09-1A"
    WHEN DATE_DIFF(c.Maxfecha, c.MinInst, DAY)<=720 AND DATE_DIFF(c.Maxfecha, c.MinInst, DAY)>360 THEN "1-2 A"
    WHEN DATE_DIFF(c.Maxfecha, c.MinInst, DAY)<=1080 AND DATE_DIFF(c.Maxfecha, c.MinInst, DAY)>720 THEN "2-3 A"
    WHEN DATE_DIFF(c.Maxfecha, c.MinInst, DAY)<=1440 AND DATE_DIFF(c.Maxfecha, c.MinInst, DAY)>1080 THEN "3-4 A"
    WHEN DATE_DIFF(c.Maxfecha, c.MinInst, DAY)>1440 THEN "+4A" END AS TENURE,
    FROM CRUCECHURN c
    GROUP BY ACT_ACCT_CD, Tenure, c.Maxfecha)

SELECT DISTINCT EXTRACT (MONTH FROM t.Maxfecha) as MES, t.TENURE, Count(DISTINCT t.ACT_ACCT_CD) AS Churners
FROM TENURE t
GROUP BY MES, TENURE
ORDER BY MES, TENURE ASC
