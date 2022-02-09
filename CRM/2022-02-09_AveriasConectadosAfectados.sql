WITH AVERIASNODOS AS(
    
SELECT DISTINCT Ticket_ID, NODO, CAST(LEFT(Fecha_Inicio,10) AS DATE) AS FechaAveria, SAFE_CAST(Clientes_Afectados AS INT64 ) AS CLIENTES_AFECTADOS
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_AVERIAS_NODOS_2020-12_A_2021-12_T`
WHERE Ticket_ID IS NOT NULL
AND (Ticket_Type = "Averia Planta Externa" OR Ticket_Type = "Averia Fibra" OR Ticket_Type = "Avería FTTH")
--GROUP BY 1,2,3
),
USUARIOSNODOS AS(
 SELECT DISTINCT Account_Number, Node_Name
 FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-13_CR_CONEXION_USUARIOS_NODOS_2021_T` U
)
SELECT 
   DISTINCT fechaaveria,Ticket_id, nodo, COUNT(DISTINCT U.Account_Number) AS USERS_GRL, 
    A.CLIENTES_AFECTADOS AS USERS_AFECTED
FROM AVERIASNODOS a 
    INNER JOIN USUARIOSNODOS u ON A.NODO = U.Node_Name
GROUP BY 1,2,3,5
ORDER BY 1,4 DESC
