WITH  

REVERSIONES AS(
SELECT DISTINCT CONTRATO, FECHA_APERTURA as FechaRever
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_TIQUETES_SERVICIO_2021-01_A_2021-11_D`
WHERE CLASE IS NOT NULL AND MOTIVO IS NOT NULL AND CONTRATO IS NOT NULL
AND SUBAREA <> "0 A 30 DIAS" AND SUBAREA <> "30 A 60 DIAS" AND SUBAREA <> "60 A 90 DIAS" 
AND SUBAREA <> "90 A 120 DIAS" AND SUBAREA <> "120 A 150 DIAS" AND SUBAREA <> "150 A 180 DIAS" 
AND SUBAREA <> "MAS DE 180" AND MOTIVO <> "LLAMADA  CONSULTA DESINSTALACION"
AND ESTADO <> "ANULADA" AND MOTIVO = "REVERSION AUTOMATICA"
GROUP BY CONTRATO,FechaRever),

FACTURACION AS (
SELECT DISTINCT CONTRATO, FECHA_APERTURA AS FechaFact
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_TIQUETES_SERVICIO_2021-01_A_2021-11_D` 
WHERE 
CLASE IS NOT NULL AND MOTIVO IS NOT NULL AND CONTRATO IS NOT NULL AND FECHA_APERTURA IS NOT NULL 
AND SUBAREA <> "0 A 30 DIAS" AND SUBAREA <> "30 A 60 DIAS" AND SUBAREA <> "60 A 90 DIAS" 
AND SUBAREA <> "90 A 120 DIAS" AND SUBAREA <> "120 A 150 DIAS" AND SUBAREA <> "150 A 180 DIAS" 
AND SUBAREA <> "MAS DE 180" AND ESTADO <> "ANULADA"
AND MOTIVO="CONSULTAS DE FACTURACION O COBRO"
GROUP BY CONTRATO, FechaFact),

/*Contratos distintos con llamadas de facturación max 2 meses después de la reversión*/
CONTRATOSLLAMADASREV AS (
SELECT DISTINCT r.CONTRATO as cReversiones, f.CONTRATO as cLlamadas, f.FechaFact, r.FechaRever,
FROM REVERSIONES r INNER JOIN FACTURACION f ON r.CONTRATO=f.CONTRATO
WHERE DATE_DIFF(f.FechaFact,r.FechaRever,DAY)<=60 AND f.FechaFact>r.FechaRever
GROUP BY r.CONTRATO,f.CONTRATO, f.FechaFact, r.FechaRever
),

/*Subconsulta que separa las personas que llamaron max 2 meses después de la reversión y las que no*/
CALLFLAGRESULT AS(
SELECT DISTINCT r.contrato AS CONTRATO, c.cReversiones , c.cLlamadas,c.FechaFact AS FechaLlamada, r.FechaRever as FechaRever,
CASE WHEN c.cLlamadas IS NOT NULL THEN "ConLlamada"
WHEN c.cLlamadas IS NULL THEN "SinLlamada" end as CallFlag
FROM REVERSIONES r LEFT JOIN CONTRATOSLLAMADASREV c ON r.CONTRATO= c.cReversiones 
GROUP BY r.contrato, c.cReversiones , c.cLlamadas,c.FechaFact, r.FechaRever
),

CHURNERSSINLLAMADA AS(SELECT DISTINCT x.NOMBRE_CONTRATO, x.FECHA_FINALIZACION as FechaChurnR
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D` x 
INNER JOIN CALLFLAGRESULT l on l.Contrato = x.NOMBRE_CONTRATO
WHERE x.TIPO_ORDEN = "DESINSTALACION" AND x.ESTADO = "FINALIZADA" 
AND x.FECHA_FINALIZACION IS NOT NULL AND x.FECHA_APERTURA IS NOT NULL
AND x.FECHA_FINALIZACION > l.FechaRever  AND DATE_DIFF ( x.FECHA_FINALIZACION, l.FechaRever, DAY) <= 60
GROUP BY x.NOMBRE_CONTRATO, x.FECHA_FINALIZACION),

CHURNERSCONLLAMADA AS(SELECT DISTINCT y.NOMBRE_CONTRATO, y.FECHA_FINALIZACION as FechaChurnF
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D` y 
INNER JOIN CALLFLAGRESULT l on l.cLlamadas = y.NOMBRE_CONTRATO
WHERE y.TIPO_ORDEN = "DESINSTALACION" AND y.ESTADO = "FINALIZADA" 
AND y.FECHA_FINALIZACION IS NOT NULL AND y.FECHA_APERTURA IS NOT NULL
AND y.FECHA_FINALIZACION > l.FechaLlamada  AND DATE_DIFF ( y.FECHA_FINALIZACION, l.FechaLlamada, DAY) <= 60
GROUP BY y.NOMBRE_CONTRATO,  y.FECHA_FINALIZACION),

CHURNFLAGRESULTSIN AS(
SELECT DISTINCT l.Contrato, l.FechaRever, x.FechaChurnR,l.CallFlag,
CASE WHEN x.FechaChurnR IS NOT NULL THEN "ChurnerSinLLamada"
WHEN x.FechaChurnR IS NULL THEN "NonChurnerSinLlamada" end as ChurnFlagR
FROM CALLFLAGRESULT l LEFT JOIN CHURNERSSINLLAMADA x ON x.NOMBRE_CONTRATO=l.CONTRATO
WHERE l.CallFlag="SinLlamada"
GROUP BY l.Contrato, l.FechaRever, x.FechaChurnR,l.CallFlag
),

CHURNFLAGRESULTCON AS(
SELECT DISTINCT l.cLlamadas, l.cReversiones,l.FechaRever,l.FechaLlamada, y.FechaChurnF, l.CallFlag,
CASE WHEN y.FechaChurnF IS NOT NULL THEN "ChurnerConLLamada"
WHEN y.FechaChurnF IS NULL THEN "NonChurnerConLlamada" end as ChurnFlagF
FROM CALLFLAGRESULT l LEFT JOIN CHURNERSCONLLAMADA y ON y.NOMBRE_CONTRATO=l.cLlamadas
WHERE l.CallFlag="ConLlamada"
GROUP BY l.cLlamadas, l.cReversiones,l.FechaRever,l.FechaLlamada, y.FechaChurnF, l.CallFlag
)

SELECT 
--extract(Month FROM rev.FechaRever) as Mes, rev.churnflagr,  COUNT(DISTINCT rev.Contrato)
extract (Month FROM fact.FechaRever) as Mes, FACT.CHURNFLAGF, COUNT (DISTINCT FACT.cLlamadas)
--FROM CHURNFLAGRESULTSIN rev
FROM CHURNFLAGRESULTCON fact
--ON extract(month from w.FechaRever)=extract(month from z.FechaRever)
--GROUP BY Mes, Churnflagr ORDER BY Mes
GROUP BY Mes, ChurnFlagF ORDER BY Mes
