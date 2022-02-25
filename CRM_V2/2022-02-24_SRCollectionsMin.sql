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
AND EXTRACT(MONTH FROM x.Formato_Fecha)=3
),
/*Subconsulta que extrae los churners del CRM considerando la máxima fecha de churn*/
CHURNERSCRM AS(
  SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CONTRATOCRM, MAX(DATE(CST_CHRN_DT)) AS Maxfecha, EXTRACT(MONTH FROM MAX(CST_CHRN_DT)) AS MesChurnF
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (MONTH FROM Maxfecha) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
FIRSTCHURN AS(
 SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CONTRATOPCHURN, Min(DATE(CST_CHRN_DT)) AS PrimerChurn, Extract(Month from Min(CST_CHRN_DT)) AS MesChurnP
    FROM  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
    GROUP BY ACT_ACCT_CD
    HAVING EXTRACT (YEAR FROM PrimerChurn) = 2021
),
REALCHURNERS AS(
 SELECT DISTINCT CONTRATOCRM, MaxFecha, PrimerChurn, MesChurnF, MesChurnP
 FROM CHURNERSCRM c  INNER JOIN FIRSTCHURN f ON c.CONTRATOCRM = f.CONTRATOPCHURN AND f.PrimerChurn <= c.MaxFecha
   GROUP BY CONTRATOCRM, MaxFecha, PrimerChurn, MesChurnF, MesChurnP
),
MOROSOSCRM AS(
    SELECT DISTINCT RIGHT(CONCAT('0000000000',CONTRATO) ,10) AS CONTRATO, FECHA_FACTURA, TIPO_SERVICIO
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_COLLECTIONS_TOTAL_2021-01_A_2021-11_D`
    WHERE TIPO_SERVICIO IN ('INTERNET', 'FTTH (JASEC)', 'HOGARES CONECTADOS','TELEFONIA','CABLE TICA') AND RANGO_FACTURA <> "1-SIN VENCER"
    GROUP BY CONTRATO, FECHA_FACTURA, TIPO_SERVICIO
),
CRUCECOLLECTIONSCRM AS(
    SELECT DISTINCT CONTRATOCRM, MaxFecha, PrimerChurn, CONTRATO
    FROM REALCHURNERS c LEFT JOIN MOROSOSCRM m ON c.CONTRATOCRM = m.CONTRATO  
    AND ((DATE_DIFF (Primerchurn, FECHA_FACTURA, DAY) >= 60 AND TIPO_SERVICIO IN ('INTERNET', 'FTTH (JASEC)', 'HOGARES CONECTADOS')
    OR DATE_DIFF (Primerchurn, FECHA_FACTURA, DAY) >=90) AND TIPO_SERVICIO IN ('HOGARES CONECTADOS','TELEFONIA','CABLE TICA'))
    GROUP BY CONTRATOCRM, CONTRATO,Maxfecha, PrimerChurn
),
CLASIFICACIONCHURN AS(
    SELECT DISTINCT CONTRATOCRM, Maxfecha, PrimerChurn,
    CASE WHEN CONTRATO IS NULL THEN CONTRATOCRM END AS VOLUNTARIO,
    CASE WHEN CONTRATO IS NOT NULL THEN CONTRATOCRM END AS INVOLUNTARIO
    FROM CRUCECOLLECTIONSCRM
    GROUP BY CONTRATOCRM, MAXFECHA, VOLUNTARIO, INVOLUNTARIO,PrimerChurn
),

/*Subconsulta que define los meses de churn*/
MESESCHURN AS(
SELECT DISTINCT CONTRATOCRM,VOLUNTARIO, INVOLUNTARIO,PrimerChurn,
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
WHEN EXTRACT(MONTH FROM PrimerChurn)=12 THEN "Diciembre" END AS Mesesitos
FROM CLASIFICACIONCHURN
)

/*Consulta final que extrae los churners de cada mes en base al mes de alta definido*/
SELECT 
Mesesitos, COUNT(DISTINCT a.CONTRATOALTA) AS CHURNERS, COUNT (DISTINCT VOLUNTARIO) AS VOL, COUNT(DISTINCT INVOLUNTARIO) AS INVOL
FROM AMBASALTAS a INNER JOIN MESESCHURN c ON c.CONTRATOCRM =a.CONTRATOALTA and Formato_Fecha < primerchurn
GROUP BY Mesesitos ORDER BY CASE WHEN Mesesitos="Enero" THEN 1
                                 WHEN Mesesitos="Febrero" THEN 2
                                 WHEN Mesesitos="Marzo" THEN 3
                                 WHEN Mesesitos="Abril" THEN 4
                                 WHEN Mesesitos="Mayo" THEN 5
                                 WHEN Mesesitos="Junio" THEN 6
                                 WHEN Mesesitos="Julio" THEN 7
                                 WHEN Mesesitos="Agosto" THEN 8
                                 WHEN Mesesitos="Septiembre"THEN 9
                                 WHEN Mesesitos="Octubre" THEN 10
                                 WHEN Mesesitos="Noviembre" THEN 11
                                 WHEN Mesesitos="Diciembre" THEN 12 END


/*Para extraer únicamente las altas por mes se debe apagar la consulta final anterior y prender la siguiente, así como apagar
 el filtro del mes del alta en AMBASALTAS*/
/*SELECT EXTRACT(MONTH FROM Formato_Fecha) AS MES, 
COUNT(DISTINCT a.Contrato)
FROM AMBASALTAS a
GROUP BY Mes ORDER BY Mes*/
