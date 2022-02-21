WITH 

/*Subconsulta que extrae los contratos que tuvieron fecha de alta en el CRM en 2021*/
ALTASCRM AS (
SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CONTRATOALTACRM, ACT_ACCT_INST_DT
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
WHERE EXTRACT(YEAR FROM ACT_ACCT_INST_DT)=2021
GROUP BY ACT_ACCT_CD, ACT_ACCT_INST_DT),

/*Subconsulta que extrae las ventas nuevas de la base de altas*/
ALTAS AS (
SELECT RIGHT(CONCAT('0000000000',Contrato) ,10) AS CONTRATOALTA, Formato_Fecha
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-20_CR_ALTAS_V3_2021-01_A_2021-12_T`  
WHERE Tipo_Venta="Nueva"
AND (Tipo_Cliente = "PROGRAMA HOGARES CONECTADOS" OR Tipo_Cliente="RESIDENCIAL" OR Tipo_Cliente="EMPLEADO")
AND extract(year from Formato_Fecha) = 2021 
AND Subcanal__Venta<>"OUTBOUND PYMES" AND Subcanal__Venta<>"INBOUND PYMES" AND Subcanal__Venta<>"HOTELERO" AND Subcanal__Venta<>"PYMES – NETCOM" 
AND Tipo_Movimiento= "Altas por venta"
AND (Motivo="VENTA NUEVA " OR Motivo="VENTA")
GROUP BY Contrato, Formato_Fecha
),

/*Subconsulta que cruza los contratos con instalaciones en el CRM y las ventas nuevas de la base de altas;
 Acá se debe definir el mes del alta a evaluar*/
AMBASALTAS AS (
SELECT x.CONTRATOALTA, x.Formato_Fecha
FROM ALTASCRM y INNER JOIN ALTAS x ON y.CONTRATOALTACRM=x.CONTRATOALTA
WHERE DATE(ACT_ACCT_INST_DT)=Formato_Fecha 
--AND EXTRACT(MONTH FROM x.Formato_Fecha)=10
),

/*Subconsulta que extrae los churners del CRM considerando la máxima fecha de churn*/
CHURNERSCRM AS(
    SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CHURNERCRM, MAX(CST_CHRN_DT) AS Maxfecha,
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
INVOLUNTARYCHURNERS AS(
 SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS INVOLCHURN, Max(CST_CHRN_DT) AS MaxChurnInvol,
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    WHERE (FI_OUTST_AGE >= 60 AND PD_BB_PROD_ID IS NOT NULL) OR (FI_OUTST_AGE >= 90 
    AND (PD_TV_PROD_ID IS NOT NULL OR PD_VO_PROD_ID IS NOT NULL))
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM MaxChurnInvol) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
INVOLUNTARYMAXCHURNERS AS(
 SELECT DISTINCT c.CHURNERCRM, MaxFecha,
 CASE WHEN i.InvolChurn IS NULL THEN CHURNERCRM END AS Voluntario,
 CASE WHEN i.InvolChurn is NOT NULL THEN CHURNERCRM END AS Involuntario
 FROM CHURNERSCRM c  LEFT JOIN INVOLUNTARYCHURNERS i ON c.CHURNERCRM = i.INVOLCHURN AND i.MaxChurnInvol = c.MaxFecha
   GROUP BY C.CHURNERCRM, MaxFecha, Voluntario, Involuntario
),

/*Subconsulta que define los meses de churn*/
MESESCHURN AS(
SELECT DISTINCT CHURNERCRM, MaxFecha, Voluntario, Involuntario,
  CASE WHEN EXTRACT(MONTH FROM MaxFecha)=1 THEN "Enero"
    WHEN EXTRACT(MONTH FROM MaxFecha)=2 THEN "Febrero"
    WHEN EXTRACT(MONTH FROM MaxFecha)=3 THEN "Marzo"
    WHEN EXTRACT(MONTH FROM MaxFecha)=4 THEN "Abril"
    WHEN EXTRACT(MONTH FROM MaxFecha)=5 THEN "Mayo"
    WHEN EXTRACT(MONTH FROM MaxFecha)=6 THEN "Junio"
    WHEN EXTRACT(MONTH FROM MaxFecha)=7 THEN "Julio"
    WHEN EXTRACT(MONTH FROM MaxFecha)=8 THEN "Agosto"
    WHEN EXTRACT(MONTH FROM MaxFecha)=9 THEN "Septiembre"
    WHEN EXTRACT(MONTH FROM MaxFecha)=10 THEN "Octubre"
    WHEN EXTRACT(MONTH FROM MaxFecha)=11 THEN "Noviembre"
    WHEN EXTRACT(MONTH FROM MaxFecha)=12 THEN "Diciembre" END AS Meses
FROM INVOLUNTARYMAXCHURNERS 
GROUP BY CHURNERCRM, MAXFECHA, Involuntario,Voluntario
)

/*Consulta final que extrae los churners de cada mes en base al mes de alta definido*/
SELECT 
Meses, COUNT(DISTINCT a.CONTRATOALTA) AS Churners , COUNT(DISTINCT VOLUNTARIO) AS Voluntarios, COUNT (DISTINCT INVOLUNTARIO) as Involuntarios
FROM AMBASALTAS a INNER JOIN MESESCHURN c ON c.CHURNERCRM =a.CONTRATOALTA
GROUP BY Meses
ORDER BY CASE                    WHEN Meses ="Enero" THEN 1
                                 WHEN Meses ="Febrero" THEN 2
                                 WHEN Meses ="Marzo" THEN 3
                                 WHEN Meses ="Abril" THEN 4
                                 WHEN Meses ="Mayo" THEN 5
                                 WHEN Meses ="Junio" THEN 6
                                 WHEN Meses ="Julio" THEN 7
                                 WHEN Meses ="Agosto" THEN 8
                                 WHEN Meses ="Septiembre"THEN 9
                                 WHEN Meses ="Octubre" THEN 10
                                 WHEN Meses ="Noviembre" THEN 11
                                 WHEN Meses ="Diciembre" THEN 12 END


/*Para extraer únicamente las altas por mes se debe apagar la consulta final anterior y prender la siguiente, así como apagar
 el filtro del mes del alta en AMBASALTAS*/
/*SELECT EXTRACT(MONTH FROM Formato_Fecha) AS MES, 
COUNT(DISTINCT a.ContratoAlta)
FROM AMBASALTAS a
GROUP BY Mes ORDER BY Mes*/
