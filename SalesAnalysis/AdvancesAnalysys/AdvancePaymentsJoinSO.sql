SELECT a.*, s.NO_ORDEN, s.FECHA_APERTURA, s.MOTIVO_ORDEN 
FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-03-08_ADELANTOS_2021_D` a
INNER JOIN  `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-01-12_CR_ORDENES_SERVICIO_2021-01_A_2021-11_D` s
ON a.Orden = s.NO_ORDEN
WHERE RUBRO= "Diferidos / Adelantos"
AND (a.Adelanto = "5.000,00" OR a.adelanto = "10.000,00")
ORDER BY a.Adelanto DESC
