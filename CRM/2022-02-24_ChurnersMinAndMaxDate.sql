WITH CHURNERSCRM AS(
    SELECT DISTINCT ACT_ACCT_CD, MAX(CST_CHRN_DT) AS Maxfecha, Extract(Month from Max(CST_CHRN_DT)) AS MesChurnF
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
FIRSTCHURN AS(
 SELECT DISTINCT ACT_ACCT_CD, Min(CST_CHRN_DT) AS PrimerChurn, Extract(Month from Max(CST_CHRN_DT)) AS MesChurnP
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (YEAR FROM PrimerChurn) = 2021
),
REALCHURNERS AS(
 SELECT DISTINCT c.ACT_ACCT_CD, MaxFecha, PrimerChurn, MesChurnF, MesChurnP
 FROM CHURNERSCRM c  INNER JOIN FIRSTCHURN f ON c.ACT_ACCT_CD = f.ACT_ACCT_CD AND f.PrimerChurn <= c.MaxFecha
   GROUP BY ACT_ACCT_CD, MaxFecha, PrimerChurn, MesChurnF, MesChurnP)
SELECT --extract(month from PrimerChurn) as MesMin
extract(month from MaxFecha) aS MesMax
, count (distinct ACT_ACCT_CD ) as NumChurners
FROM REALCHURNERS 
GROUP BY --MesMin 
MesMax
ORDER BY --MesMin
MesMax
