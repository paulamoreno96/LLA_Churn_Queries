CREATE OR REPLACE TABLE  
 `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_ene_2021_mar_2022_D`
AS
SELECT * FROM
(
   /* SELECT * EXCEPT (FI_OUTST_AGE,OLDEST_UNPAID_BILL_DT), safe_cast(fi_outst_age as float64) as fi_outst_age, safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_ene_mar_2021_P`
    UNION ALL
    SELECT * EXCEPT (FI_OUTST_AGE,OLDEST_UNPAID_BILL_DT), safe_cast(fi_outst_age as float64) as fi_outst_age, safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_abr_jun_2021_P`
    UNION ALL*/
    SELECT * EXCEPT (FI_OUTST_AGE,OLDEST_UNPAID_BILL_DT), safe_cast(fi_outst_age as float64) as fi_outst_age, safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_jul_sep_2021_P`
    UNION ALL
    SELECT * EXCEPT (FI_OUTST_AGE,OLDEST_UNPAID_BILL_DT), safe_cast(fi_outst_age as float64) as fi_outst_age, safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_oct_dic_2021_P`
    UNION ALL
    SELECT * EXCEPT (FI_OUTST_AGE,OLDEST_UNPAID_BILL_DT), safe_cast(fi_outst_age as float64) as fi_outst_age, safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_ene_mar_2022_P`
)
