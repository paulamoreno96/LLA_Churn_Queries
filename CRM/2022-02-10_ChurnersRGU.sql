WITH CHURNERSBB AS(
    SELECT DISTINCT ACT_ACCT_CD AS CONTRATOSBB, MAX(CST_CHRN_DT) AS MaxfechaBB
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    WHERE PD_BB_PROD_ID IS NOT NULL
    GROUP BY CONTRATOSBB
    HAVING EXTRACT (MONTH FROM MaxfechaBB) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
CHURNERSTV AS(
     SELECT DISTINCT ACT_ACCT_CD AS CONTRATOSTV, MAX(CST_CHRN_DT) AS MaxfechaTV
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    WHERE PD_TV_PROD_ID IS NOT NULL
    GROUP BY CONTRATOSTV
    HAVING EXTRACT (MONTH FROM MaxfechaTV) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
CHURNERSVO AS(
         SELECT DISTINCT ACT_ACCT_CD AS CONTRATOSVO, MAX(CST_CHRN_DT) AS MaxfechaVO
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-02-02_CRM_BULK_FILE_FINAL_HISTORIC_DATA_2021_D`
    WHERE PD_VO_PROD_ID IS NOT NULL
   GROUP BY CONTRATOSVO
    HAVING EXTRACT (MONTH FROM MaxfechaVO) = EXTRACT (MONTH FROM MAX(FECHA_EXTRACCION))
),
CHURNBBMES AS(
    SELECT EXTRACT(MONTH FROM MaxfechaBB) AS MES, COUNT(DISTINCT CONTRATOSBB) AS BBCHURNERS
    FROM CHURNERSBB
    GROUP BY MES
),
CHURNTVMES AS(
  SELECT EXTRACT(MONTH FROM MaxfechaTV) AS MES, COUNT(DISTINCT CONTRATOSTV) AS TVCHURNERS
    FROM CHURNERSTV
    GROUP BY MES
),
CHURNVOMES AS(
      SELECT EXTRACT(MONTH FROM MaxfechaVO) AS MES, COUNT(DISTINCT CONTRATOSVO) AS VOCHURNERS
    FROM CHURNERSVO
    GROUP BY MES
)
SELECT b.MES, BBCHURNERS , TVCHURNERS, VOCHURNERS, SUM(BBCHURNERS + TVCHURNERS + VOCHURNERS)
FROM CHURNBBMES  b INNER JOIN CHURNTVMES t on b.MES = t.MES INNER JOIN CHURNVOMES v on b.mes = v.mes
GROUP BY MES, BBCHURNERS, TVCHURNERS, VOCHURNERS
ORDER BY MES ASC
