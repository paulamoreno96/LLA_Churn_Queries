WITH UBICACIONNODOS AS(
SELECT REPLACE (ID_NODO, ' ', '_') AS ID_NODO_ADJ, PROVINCIA
--, CANTON, DISTRITO
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_GEO_UBICACION_NODOS_2021_T`
),
NODOSAVERIAS AS(
SELECT DISTINCT Ticket_ID, NODO, CAST(LEFT(Fecha_Inicio,10) AS DATE) AS FechaAveria
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_AVERIAS_NODOS_2020-12_A_2021-12_T`
WHERE Ticket_ID IS NOT NULL
--AND (Ticket_Type = "Averia Planta Externa" OR Ticket_Type = "Averia Fibra" OR Ticket_Type = "Avería FTTH")
GROUP BY Ticket_ID, NODO, FechaAveria)
SELECT u.Provincia as Provincia, 
--u.Canton as Canton, u.Distrito as Distrito,
Count(distinct a.Ticket_ID) as NumTick
FROM UBICACIONNODOS u INNER JOIN NODOSAVERIAS a ON u.ID_NODO_ADJ = a.NODO
GROUP BY Provincia
--, Canton, Distrito 
ORDER BY NumTick DESC 
