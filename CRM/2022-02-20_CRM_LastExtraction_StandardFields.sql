CREATE OR REPLACE TABLE  
 `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_ene_2021_mar_2022_D`
AS
SELECT * FROM
(
    SELECT  ORG_CNTRY, CST_CUST_NAME, CST_CUST_ID, ACT_ACCT_CD,ACT_CONTACT_MAIL_1,ACT_ACCT_INST_DT,
    ACT_ACCT_SIGN_DT, C_CUST_AGE,PD_VO_PROD_NM,PD_VO_PROD_ID,PD_BB_PROD_NM, PD_BB_PROD_ID, PD_TV_PROD_CD, PD_TV_PROD_ID,
    PD_MIX_CD, PD_MIX_NM, VO_FI_TOT_MRC_AMT, VO_FI_TOT_MRC_AMT_DESC, BB_FI_TOT_MRC_AMT, BB_FI_TOT_MRC_AMT_DESC,
    TV_FI_TOT_MRC_AMT, TV_FI_TOT_MRC_AMT_DESC,safe_cast(TOT_BILL_AMT as float64) as TOT_BILL_AMT, SAFE_CAST(TOT_DESC_AMT AS FLOAT64) AS TOT_DESC_AMT,  safe_cast(fi_outst_age as float64) as FI_OUTST_AGE,
    LOAD_DT, FI_BILL_DT_M0, LST_PYM_DT,  safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT,
    ACT_PRVNC_CD, ACT_CANTON_CD, ACT_RGN_CD, TV_ACT_AREA_CD, ACT_CUST_TYP, ACT_CUST_TYP_NM, CST_CHRN_DT, FECHA_EXTRACCION
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_ene_mar_2021_P`
    UNION ALL
    SELECT ORG_CNTRY, CST_CUST_NAME, CST_CUST_ID, ACT_ACCT_CD,ACT_CONTACT_MAIL_1,ACT_ACCT_INST_DT,
    ACT_ACCT_SIGN_DT, C_CUST_AGE,PD_VO_PROD_NM,PD_VO_PROD_ID,PD_BB_PROD_NM, PD_BB_PROD_ID, PD_TV_PROD_CD, PD_TV_PROD_ID,
    PD_MIX_CD, PD_MIX_NM, VO_FI_TOT_MRC_AMT, VO_FI_TOT_MRC_AMT_DESC, BB_FI_TOT_MRC_AMT, BB_FI_TOT_MRC_AMT_DESC,
    TV_FI_TOT_MRC_AMT, TV_FI_TOT_MRC_AMT_DESC,TOT_BILL_AMT, TOT_DESC_AMT,  safe_cast(fi_outst_age as float64) as FI_OUTST_AGE,
    LOAD_DT, FI_BILL_DT_M0, LST_PYM_DT,  safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT,
    ACT_PRVNC_CD, ACT_CANTON_CD, ACT_RGN_CD, TV_ACT_AREA_CD, ACT_CUST_TYP, ACT_CUST_TYP_NM, CST_CHRN_DT, FECHA_EXTRACCION
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_abr_jun_2021_P`
    UNION ALL
    SELECT ORG_CNTRY, CST_CUST_NAME, CST_CUST_ID, ACT_ACCT_CD,ACT_CONTACT_MAIL_1,ACT_ACCT_INST_DT,
    ACT_ACCT_SIGN_DT, C_CUST_AGE,PD_VO_PROD_NM,PD_VO_PROD_ID,PD_BB_PROD_NM, PD_BB_PROD_ID, PD_TV_PROD_CD, PD_TV_PROD_ID,
    PD_MIX_CD, PD_MIX_NM, VO_FI_TOT_MRC_AMT, VO_FI_TOT_MRC_AMT_DESC, BB_FI_TOT_MRC_AMT, BB_FI_TOT_MRC_AMT_DESC,
    TV_FI_TOT_MRC_AMT, TV_FI_TOT_MRC_AMT_DESC,TOT_BILL_AMT, TOT_DESC_AMT,  safe_cast(fi_outst_age as float64) as FI_OUTST_AGE,
    LOAD_DT, FI_BILL_DT_M0, LST_PYM_DT,  safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT,
    ACT_PRVNC_CD, ACT_CANTON_CD, ACT_RGN_CD, TV_ACT_AREA_CD, ACT_CUST_TYP, ACT_CUST_TYP_NM, CST_CHRN_DT, FECHA_EXTRACCION
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_jul_sep_2021_P`
    UNION ALL
    SELECT ORG_CNTRY, CST_CUST_NAME, CST_CUST_ID, ACT_ACCT_CD,ACT_CONTACT_MAIL_1,ACT_ACCT_INST_DT,
    ACT_ACCT_SIGN_DT, C_CUST_AGE,PD_VO_PROD_NM,PD_VO_PROD_ID,PD_BB_PROD_NM, PD_BB_PROD_ID, PD_TV_PROD_CD, PD_TV_PROD_ID,
    PD_MIX_CD, PD_MIX_NM, VO_FI_TOT_MRC_AMT, VO_FI_TOT_MRC_AMT_DESC, BB_FI_TOT_MRC_AMT, BB_FI_TOT_MRC_AMT_DESC,
    TV_FI_TOT_MRC_AMT, TV_FI_TOT_MRC_AMT_DESC,TOT_BILL_AMT, TOT_DESC_AMT,  safe_cast(fi_outst_age as float64) as FI_OUTST_AGE,
    LOAD_DT, FI_BILL_DT_M0, LST_PYM_DT,  safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT,
    ACT_PRVNC_CD, ACT_CANTON_CD, ACT_RGN_CD, TV_ACT_AREA_CD, ACT_CUST_TYP, ACT_CUST_TYP_NM, CST_CHRN_DT, FECHA_EXTRACCION
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_oct_dic_2021_P`
    UNION ALL
    SELECT ORG_CNTRY, CST_CUST_NAME, CST_CUST_ID, ACT_ACCT_CD,ACT_CONTACT_MAIL_1,ACT_ACCT_INST_DT,
    ACT_ACCT_SIGN_DT, C_CUST_AGE,PD_VO_PROD_NM,PD_VO_PROD_ID,PD_BB_PROD_NM, PD_BB_PROD_ID, PD_TV_PROD_CD, PD_TV_PROD_ID,
    PD_MIX_CD, PD_MIX_NM, VO_FI_TOT_MRC_AMT, VO_FI_TOT_MRC_AMT_DESC, BB_FI_TOT_MRC_AMT, BB_FI_TOT_MRC_AMT_DESC,
    TV_FI_TOT_MRC_AMT, TV_FI_TOT_MRC_AMT_DESC,TOT_BILL_AMT, TOT_DESC_AMT,  safe_cast(fi_outst_age as float64) as FI_OUTST_AGE,
    LOAD_DT, FI_BILL_DT_M0, LST_PYM_DT,  safe_cast(OLDEST_UNPAID_BILL_DT as date) as OLDEST_UNPAID_BILL_DT,
    ACT_PRVNC_CD, ACT_CANTON_CD, ACT_RGN_CD, TV_ACT_AREA_CD, ACT_CUST_TYP, ACT_CUST_TYP_NM, CST_CHRN_DT, FECHA_EXTRACCION
    FROM `gcp-bia-tmps-vtr-dev-01.gcp_temp_cr_dev_01.2022-04-20_Historical_CRM_ene_mar_2022_P`
)