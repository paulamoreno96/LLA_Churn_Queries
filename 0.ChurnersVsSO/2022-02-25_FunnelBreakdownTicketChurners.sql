WITH
/* Subconsulta con el número de contratos únicos con tiquetes de avería por mes*/
  CONTRATOSTA AS(
  SELECT DISTINCT RIGHT(CONCAT('0000000000',CONTRATO) ,10) AS CONTRATO, FECHA_APERTURA
  FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-14_CR_TIQUETES_AVERIAS_2021-01_A_2021-11_D`
  WHERE
    ESTADO <> "ANULADA" AND CLASE IS NOT NULL AND MOTIVO IS NOT NULL AND CONTRATO IS NOT NULL 
  /*Esta sentencia agrega el filtro de que el tiquete sea un truckroll, al quitarle el comentario obtenemos el número de contratos únicos con truckrolls por mes*/
    AND TIPO_ATENCION = "TR"
  GROUP BY
    CONTRATO, FECHA_APERTURA ),
/*Subconsulta que saca los churners por mes*/ 
  CHURNERSSO AS
(SELECT DISTINCT RIGHT(CONCAT('0000000000',NOMBRE_CONTRATO) ,10) AS CONTRATOSO, FECHA_APERTURA
 FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D`
 WHERE
  TIPO_ORDEN = "DESINSTALACION" 
  AND (ESTADO <> "CANCELADA" OR ESTADO <> "ANULADA")
 AND FECHA_APERTURA IS NOT NULL
 ),
  CHURNERSMES AS(
  SELECT
  DISTINCT CONTRATOSO,FECHA_APERTURA
  FROM CHURNERSSO t
  INNER JOIN `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-15_ChurnersDefinitivos_D` c
  ON t.contratoso = c.FORMATOCONTRATOCRM AND c.Maxfecha >= t.FECHA_APERTURA AND date_diff(c.Maxfecha, t.FECHA_APERTURA, MONTH) <= 3
  ) 
/*Consulta final que cruza los contratos con llamadas técnicas con los churners que se desinstalan hasta 2 meses después de tener la solicitud*/
SELECT
  EXTRACT (MONTH FROM l.FECHA_APERTURA) AS MES, COUNT(DISTINCT c.CONTRATOSO)
FROM CONTRATOSTA l INNER JOIN CHURNERSMES c ON l.CONTRATO = c.CONTRATOSO
WHERE c.FECHA_APERTURA >= l.FECHA_APERTURA AND DATE_DIFF (c.FECHA_APERTURA, l.FECHA_APERTURA, DAY) <= 60
GROUP BY MES
ORDER BY MES
