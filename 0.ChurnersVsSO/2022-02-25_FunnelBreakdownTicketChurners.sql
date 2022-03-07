/*Subconsulta que saca todos los contratos únicos con tiquetes de servicio exceptuando aquellos de la gestión de cobranzas y las llamadas para solicitar desinstalación*/
WITH
  CONTRATOSLLAMADAS AS(
  SELECT DISTINCT RIGHT(CONCAT('0000000000',CONTRATO) ,10) AS CONTRATO, FECHA_APERTURA
  FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_TIQUETES_SERVICIO_2021-01_A_2021-11_D`
  WHERE
    CLASE IS NOT NULL AND MOTIVO IS NOT NULL AND CONTRATO IS NOT NULL AND ESTADO <> "ANULADA"
    AND TIPO <> "GESTION COBRO"
    AND MOTIVO <> "LLAMADA  CONSULTA DESINSTALACION"
  GROUP BY CONTRATO,FECHA_APERTURA ),
/* Subconsulta que extrae los churners de service orders*/
CHURNERSSO AS
(SELECT DISTINCT RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) AS CONTRATOSO, FECHA_APERTURA
 FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D`
 WHERE
  TIPO_ORDEN = "DESINSTALACION" 
  AND (ESTADO <> "CANCELADA" OR ESTADO <> "ANULADA")
 AND FECHA_APERTURA IS NOT NULL
 ),
/*Subconsulta que saca los churners por mes según la fecha de registro en el CRM*/
 CHURNERSJOIN AS(
  SELECT
  DISTINCT CONTRATOSO,FECHA_APERTURA
  FROM CHURNERSSO t
  INNER JOIN `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-15_ChurnersDefinitivos_D` c
  ON t.contratoso = c.CONTRATOCRM AND c.FechaChurn >= t.FECHA_APERTURA AND date_diff(c.FechaChurn, t.FECHA_APERTURA, MONTH) <= 3
  ) 
/*Consulta final que cruza los contratos con tiquetes con los churners que se desinstalan hasta 3 meses después de tener un tiquete*/
SELECT
 DATE_TRUNC(l.FECHA_APERTURA, MONTH) AS MES, COUNT(DISTINCT CONTRATOSO) AS CHURNERS
FROM CONTRATOSLLAMADAS l INNER JOIN CHURNERSJOIN c ON CONTRATO = CONTRATOSO
WHERE c.FECHA_APERTURA> l.FECHA_APERTURA AND DATE_DIFF (c.FECHA_APERTURA, l.FECHA_APERTURA, DAY) <= 60
GROUP BY MES
ORDER BY MES
