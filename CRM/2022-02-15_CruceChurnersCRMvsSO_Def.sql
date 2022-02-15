WITH CHURNERSSO AS
(SELECT DISTINCT RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) AS CONTRATOSO, FECHA_APERTURA
 FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D`
 WHERE
  TIPO_ORDEN = "DESINSTALACION" 
  AND (ESTADO <> "CANCELADA" OR ESTADO <> "ANULADA")
 AND FECHA_APERTURA IS NOT NULL
 ORDER BY CONTRATOSO),
CHURNERSCRM AS
( SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CONTRATOCRM,  MAX(CST_CHRN_DT) AS Maxfecha
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
 GROUP BY CONTRATOCRM
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION)) 
 ),
CRUCECHURNERS AS(
SELECT CONTRATOSO, CONTRATOCRM, EXTRACT (MONTH FROM c.Maxfecha) AS MesC, 
EXTRACT(MONTH FROM s.FECHA_APERTURA ) AS MesS
FROM CHURNERSCRM c LEFT JOIN CHURNERSSO s ON CONTRATOSO = CONTRATOCRM 
AND c.Maxfecha >= s.FECHA_APERTURA AND date_diff(c.Maxfecha, s.FECHA_APERTURA, MONTH) <= 3
GROUP BY contratoso, contratoCRM, MesC, MesS
)
SELECT
 c.MesC
 , count(distinct contratoCRM) as ChurnersCRM, Count(distinct contratoso) AS ChurnersJoinSO
FROM CRUCECHURNERS c
GROUP BY c.MesC
Order by c.MesC
