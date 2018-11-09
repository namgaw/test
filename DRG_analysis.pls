
Create or replace procedure DRG_analysis AS
BEGIN

/*
    Item 600 - final coded DRG
    Item 602 - DRG id type
    Item 652 - DRG weight
    query CHRON_DATA_DICT@clrprod for complete list of items
*/

INSERT INTO DrgChange
(HAR,
 Coding_date,
 Coder_id ,
  Original_drg_desc ,
  Original_drg_code,
  Original_drg_weight ,
  Original_grouper,
  Revised_drg_desc,
 Revised_drg_code,
 Revised_drg_weight,
 Revised_grouper
 )
SELECT
a.hsp_account_id,
a.INIT_CODING_DATE, 
a.CODING_STS_USER_ID,
aud.old_external_value,
NULL,
NULL,
NULL,
drg.drg_name,
b.drg_mpi_code ,
a.BILL_DRG_WEIGHT,
idt.id_type_name
FROM
    HSP_ACCOUNT@clrprod a 
join 
    HSP_ACCT_MULT_DRGS@clrprod b
on
    b.drg_id = a.final_drg_id and 	
    b.HSP_ACCOUNT_ID = a.hsp_account_id
JOIN
    AUDIT_ITM_HSP_ACCT@clrprod aud
ON
    aud.account_id = a.hsp_account_id
    AND
    aud.change_time = a.coding_datetime
JOIN
    IDENTITY_ID_TYPE@clrprod idt
ON
    idt.id_type = a.BILL_DRG_IDTYPE_ID
JOIN CLARITY_DRG@clrprod drg
ON
    drg.drg_id = a.final_drg_id 
WHERE
    b.DRG_BILLING_FLAG_YN = 'Y' AND
    a.coding_sts_user_id = 'MAMENDEZ' 
   AND
----    a.disch_date_time >= TO_DATE( '2018-01-01','YYYY-MM-DD') AND
    aud.item = 600 AND -- IN (600,602,652) AND 
    aud.LINE = 1
ORDER BY 
    INIT_CODING_DATE;

UPDATE
    DrgChange
SET Original_drg_code =
    (SELECT 
        mpi.mpi_id 
    FROM
        HSP_ACCOUNT@clrprod a 
    JOIN AUDIT_ITM_HSP_ACCT@clrprod aud
ON
    aud.account_id = a.hsp_account_id
    AND
    trunc(aud.change_time) = trunc(a.coding_datetime)
JOIN
IDENTITY_ID_TYPE@clrprod idt
ON
idt.id_type = a.BILL_DRG_IDTYPE_ID
JOIN CLARITY_DRG@clrprod drg
ON
drg.drg_id = aud.old_internal_value
JOIN
    CLARITY_DRG_MPI_ID@clrprod  mpi
ON  aud.old_internal_value = mpi.drg_id AND
     a.BILL_DRG_IDTYPE_ID = mpi.mpi_id_type
JOIN 
    DrgChange drgc
ON    a.hsp_account_id = drgc.har
    WHERE
  --  a.hsp_account_id=1401054753 AND
    a.coding_sts_user_id = 'MAMENDEZ' 
    AND
 aud.item = 600 
 AND
 --AND -- IN (600,602,652) AND 
aud.LINE = 1
    );

UPDATE
    DrgChange
SET Original_grouper =
    (SELECT 
        aud.old_external_value
    FROM
        HSP_ACCOUNT@clrprod a 
    JOIN AUDIT_ITM_HSP_ACCT@clrprod aud
    ON
        aud.account_id = a.hsp_account_id
    AND
        trunc(aud.change_time) = trunc(a.coding_datetime)
    JOIN 
    DrgChange drgc
    ON a.hsp_account_id = drgc.har
    WHERE
    --a.hsp_account_id=1401054753 AND
        a.coding_sts_user_id = 'MAMENDEZ' AND
        aud.item = 602 AND -- IN (600,602,652) AND 
        aud.LINE = 1 );
--
--UPDATE
--    DrgChange
--SET Original_drg_weight =
--    (select new_external_value from  AUDIT_ITM_HSP_ACCT@clrprod
-- WHERE account_id = 1401054753
--AND item= 652
-- AND 
--LINE = 1
--ORDER by CHANGE_TIME
--FETCH FIRST 1 rows only );
        
UPDATE
    DrgChange
SET Drg_weight_change = Revised_drg_weight - original_drg_weight;

  
COMMIT;


END DRG_analysis;