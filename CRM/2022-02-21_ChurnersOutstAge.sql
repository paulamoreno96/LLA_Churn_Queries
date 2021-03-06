WITH CHURNERSCRM AS(
    SELECT DISTINCT ACT_ACCT_CD, MAX(CST_CHRN_DT) AS Maxfecha,
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
INVOLUNTARYCHURNERS AS(
 SELECT DISTINCT ACT_ACCT_CD, Max(CST_CHRN_DT) AS MaxChurnInvol, 
 CASE WHEN FI_OUTST_AGE = 60 THEN ACT_ACCT_CD END AS churners60,
 CASE WHEN FI_OUTST_AGE = 90 THEN ACT_ACCT_CD END AS CHURNERS90,
 CASE WHEN FI_OUTST_AGE > 90 THEN ACT_ACCT_CD END AS CHURNERSMAS
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    WHERE (FI_OUTST_AGE >= 60 AND PD_BB_PROD_ID IS NOT NULL) OR (FI_OUTST_AGE >= 90 
    AND (PD_TV_PROD_ID IS NOT NULL OR PD_VO_PROD_ID IS NOT NULL))
    GROUP BY ACT_ACCT_CD, FI_OUTST_AGE
    HAVING EXTRACT (MONTH FROM MaxChurnInvol) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
INVOLUNTARYMAXCHURNERS AS(
 SELECT DISTINCT c.ACT_ACCT_CD AS CHURNERS, MaxFecha as  MaxChurnInvol, CHURNERS60, CHURNERS90, CHURNERSMAS
 FROM CHURNERSCRM c  INNER JOIN INVOLUNTARYCHURNERS i ON c.ACT_ACCT_CD = i.ACT_ACCT_CD AND i.MaxChurnInvol = c.MaxFecha
   WHERE i.ACT_ACCT_CD IS NOT NULL
   GROUP BY CHURNERS, MaxFecha, CHURNERS60, CHURNERS90, CHURNERSMAS
)
SELECT extract(month from maxchurninvol) as mes, COUNT(DISTINCT CHURNERS) AS CHURNERS, COUNT (DISTINCT CHURNERS60) AS CHURN60, COUNT(DISTINCT CHURNERS90) AS CHURN90, COUNT(DISTINCT CHURNERSMAS) AS CHURNMAS
FROM INVOLUNTARYMAXCHURNERS 
GROUP BY MES
ORDER BY MES
