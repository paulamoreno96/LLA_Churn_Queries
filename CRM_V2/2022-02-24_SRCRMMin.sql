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
AND EXTRACT(MONTH FROM x.Formato_Fecha)=10
),

/*Subconsulta que extrae los churners del CRM considerando la máxima fecha de churn*/
CHURNERSCRM AS(
    SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS ChurnerCRM, MAX(CST_CHRN_DT) AS Maxfecha,  Extract(Month from Max(CST_CHRN_DT)) AS MesChurnF
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
FIRSTCHURN AS(
 SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS FirstChurner, Min(CST_CHRN_DT) AS PrimerChurn, Extract(Month from Min(CST_CHRN_DT)) AS MesChurnP
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (YEAR FROM PrimerChurn) = 2021
),
REALCHURNERS AS(
 SELECT DISTINCT c.ChurnerCRM, MaxFecha, PrimerChurn, MesChurnF, MesChurnP
 FROM CHURNERSCRM c  INNER JOIN FIRSTCHURN f ON c.ChurnerCRM = f.FirstChurner AND f.PrimerChurn <= c.MaxFecha
   GROUP BY ChurnerCRM, MaxFecha, PrimerChurn, MesChurnF, MesChurnP),

INVOLUNTARYCHURNERS AS(
 SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS InvolChurner, CST_CHRN_DT AS ChurnDate,
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    WHERE (FI_OUTST_AGE >= 60 AND PD_BB_PROD_ID IS NOT NULL) OR (FI_OUTST_AGE >= 90 AND (PD_TV_PROD_ID IS NOT NULL OR PD_VO_PROD_ID IS NOT NULL)) 
    GROUP BY ACT_ACCT_CD, ChurnDate
),
CHURNTYPEFINALCHURNERS AS(
 SELECT DISTINCT c.ChurnerCRM, MaxFecha, PrimerChurn, MesChurnF, MesChurnP,
 CASE WHEN t.InvolChurner IS NULL THEN C.ChurnerCRM END AS Voluntario,
 CASE WHEN t.Involchurner IS NOT NULL THEN C.ChurnerCRM END AS Involuntario
 FROM REALCHURNERS c  LEFT JOIN iNVOLUNTARYCHURNERS t ON c.ChurnerCRM = t.InvolChurner AND t.churndate = primerchurn
GROUP BY ChurnerCRM, MaxFecha, PrimerChurn, MesChurnF, MesChurnP, Voluntario, Involuntario
),
/*Subconsulta que define los meses de churn*/
MESESCHURN AS(
SELECT DISTINCT CHURNERCRM, MaxFecha, PrimerChurn, Voluntario, Involuntario,
  CASE WHEN EXTRACT(MONTH FROM PrimerChurn)=1 THEN "Enero"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=2 THEN "Febrero"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=3 THEN "Marzo"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=4 THEN "Abril"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=5 THEN "Mayo"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=6 THEN "Junio"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=7 THEN "Julio"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=8 THEN "Agosto"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=9 THEN "Septiembre"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=10 THEN "Octubre"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=11 THEN "Noviembre"
    WHEN EXTRACT(MONTH FROM PrimerChurn)=12 THEN "Diciembre" END AS Meses
FROM CHURNTYPEFINALCHURNERS
GROUP BY CHURNERCRM, MAXFECHA, Involuntario,Voluntario, PrimerChurn
)

/*Consulta final que extrae los churners de cada mes en base al mes de alta definido*/
SELECT 
Meses, COUNT(DISTINCT a.CONTRATOALTA) AS Churners , COUNT(DISTINCT VOLUNTARIO) AS Voluntarios, COUNT (DISTINCT INVOLUNTARIO) as Involuntarios
FROM AMBASALTAS a INNER JOIN MESESCHURN c ON c.CHURNERCRM =a.CONTRATOALTA  AND Formato_Fecha < Date(PrimerChurn)
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
