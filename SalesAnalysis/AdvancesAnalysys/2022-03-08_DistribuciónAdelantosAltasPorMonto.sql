/* Subconsulta que cruza los adelantos con las órdenes de servicio mediante el tiquete y el contrato*/
WITH CRUCEORDENESADELANTOS AS(
SELECT a.*, s.NO_ORDEN, s.FECHA_APERTURA, s.MOTIVO_ORDEN, RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) AS CONTRATO_ORDEN,
CASE WHEN a.adelanto = "5.000,00" THEN Contrato END AS ADELANTOS5000,
CASE WHEN a.adelanto = "10.000,00" THEN Contrato END AS ADELANTOS10000
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-03-08_ADELANTOS_2021_D` a
INNER JOIN  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D` s
ON a.Orden = s.NO_ORDEN AND RIGHT(CONCAT('0000000000',s.NOMBRE_CONTRATO) ,10) = RIGHT(CONCAT('0000000000',a.CONTRATO) ,10)
WHERE RUBRO= "Diferidos / Adelantos"
AND (a.Adelanto = "5.000,00" OR a.adelanto = "10.000,00")
ORDER BY a.Adelanto DESC
),
/* Subconsulta con las altas de cada mes de acuerdo a los filtros definidos*/
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
/*Subconsulta que extrae los contratos que tuvieron fecha de alta en el CRM en 2021*/
ALTASCRM AS (
SELECT DISTINCT RIGHT(CONCAT('0000000000',ACT_ACCT_CD) ,10) AS CONTRATOALTACRM, ACT_ACCT_INST_DT
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-16_FINAL_HISTORIC_CRM_FILE_2021_D`
WHERE EXTRACT(YEAR FROM ACT_ACCT_INST_DT)=2021
GROUP BY ACT_ACCT_CD, ACT_ACCT_INST_DT
),
/*Cruce de las altas con altas del CRM*/
CRUCEALTAS AS (
SELECT x.CONTRATOALTA, x.Formato_Fecha
FROM ALTASCRM y INNER JOIN ALTAS x ON y.CONTRATOALTACRM=x.CONTRATOALTA
WHERE DATE(ACT_ACCT_INST_DT)=Formato_Fecha 
)
/*Cruce final que extrae la cuenta de tiquetes, contratos con adelantos por monto y contratos sin adelantos por mes*/
SELECT DATE_TRUNC(Formato_Fecha, MONTH) AS MESALTA,COUNT(DISTINCT CONTRATOALTA) AS NumContratosAltas, COUNT(DISTINCT Orden) AS NumTiquetesAdelantos, COUNT(DISTINCT Contrato) AS NumContratosAdelantos, COUNT (DISTINCT ADELANTOS5000) AS Num5000 , COUNT(DISTINCT ADELANTOS10000) AS Num10000, (COUNT(DISTINCT ContratoAlta)- COUNT(DISTINCT Contrato)) as NumContratosNoAdelantos
FROM CRUCEORDENESADELANTOS c RIGHT JOIN CRUCEALTAS a ON c.CONTRATO_ORDEN = a.CONTRATOALTA AND ABS(DATE_DIFF(c.FECHA_APERTURA, a.Formato_Fecha, DAY)) <= 10
GROUP BY MESALTA
ORDER BY MESALTA
