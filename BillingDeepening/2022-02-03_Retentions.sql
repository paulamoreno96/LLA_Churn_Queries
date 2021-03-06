WITH

Retenidos AS(
SELECT DISTINCT Contrato, DATE(FECHA_FINALIZACION) as FechaTiquete
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_TIQUETES_GENERALES_DE_DESCONEXIONES_T` 
WHERE
Contrato IS NOT NULL AND FECHA_FINALIZACION IS NOT NULL
AND SOLUCION_FINAL="RETENIDO"
AND EXTRACT (YEAR FROM FECHA_FINALIZACION) = 2021
GROUP BY Contrato, FechaTiquete)

SELECT COUNT(DISTINCT Contrato), EXTRACT(MONTH FROM FechaTiquete) as Mes
FROM Retenidos
GROUP BY Mes ORDER BY Mes
