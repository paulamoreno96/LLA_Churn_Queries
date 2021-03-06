WITH CHURNERSCRM AS(
    SELECT DISTINCT ACT_ACCT_CD, MAX(DATE(CST_CHRN_DT)) AS Maxfecha
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING DATE_TRUNC(Maxfecha, MONTH) = DATE_TRUNC(MAX(FECHA_EXTRACCION), MONTH)
),
CRUCECHURNERSPREVIOS AS(
    SELECT DISTINCT t.ACT_ACCT_CD as Contrato, c.ACT_ACCT_CD as ContratoChurner, DATE(t.CST_CHRN_DT) as FechaChurn, c.MaxFecha as FechaChurnFinal, Fecha_Extraccion,
    CASE
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "3P"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "2P - BB+TV"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - BB+VO"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NOT NULL THEN "2P - TV+VO"
    WHEN  PD_BB_PROD_ID IS NOT NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NULL THEN "1P - BB"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NOT NULL AND PD_VO_PROD_ID IS NULL THEN "1P - TV"
    WHEN  PD_BB_PROD_ID IS NULL AND PD_TV_PROD_ID IS NULL AND PD_VO_PROD_ID IS NOT NULL THEN "1P - VO"
    END AS PFLAG
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D` t
    INNER JOIN CHURNERSCRM c ON c.ACT_ACCT_CD = t.ACT_ACCT_CD AND  DATE(CST_CHRN_DT) <= MaxFecha
    WHERE DATE(t.CST_CHRN_DT) = FECHA_EXTRACCION 
),
CHURNCRONOLOGICO AS(
    SELECT DISTINCT c.ContratoChurner, c.FechaChurnFinal, c.FechaChurn, Pflag, 
    LAG (PFLAG) OVER (PARTITION BY c.ContratoChurner ORDER BY c.FechaChurn ASC) AS PlanChurnAnterior,
    LAG (PFLAG,2) OVER (PARTITION BY c.ContratoChurner ORDER BY c.FechaChurn ASC) AS PlanChurnAnterior2,
    FROM CRUCECHURNERSPREVIOS c
)
,
CHURNJOURNEYMAXFECHA AS(
    SELECT c.*
    FROM CHURNCRONOLOGICO c INNER JOIN CHURNERSCRM t ON c.ContratoChurner = t.ACT_ACCT_CD AND 
    c.FechaChurn = t.MaxFecha
)
SELECT DISTINCT DATE_TRUNC(FechaChurnFinal, MONTH) as MesChurnFinal, Pflag, PlanChurnAnterior, PlanChurnAnterior2,
COUNT (DISTINCT ContratoChurner) as NumCasos
FROM CHURNJOURNEYMAXFECHA 
GROUP BY MesChurnFinal, Pflag, PlanChurnAnterior, PlanChurnAnterior2
ORDER BY MesChurnFinal
