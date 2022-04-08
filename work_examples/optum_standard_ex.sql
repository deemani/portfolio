/* text may be missing or truncated for privacy */



/*  1. o */

-- 4 possible conditions:
--      1. Obs result >= 30
--      2. Obs result >= 27 & a comdorbid () dx code -- edited for privacy
--      3. o dx code -- edited for privacy
--      4. Rx

-- // Condition 1: Obs Result >= 30 \\ --

-- build obs table of just BMI for future use
create table obs_bmi as(
select
    ptid,
    obs_date,
    obs_type,
    obs_result
from
    production.obs_table
where
    obs_type = 'BMI');

select count(1) from obs_bmi;


-- buiild table for condition 1
create table o_c1 as (
select
    distinct ptid,
    obs_result
from
     obs_bmi
where
    obs_result >= 30 );

select count(1), count(distinct ptid) from o_c1;


-- // Condition 2: Obs result >= 27 & a comdorbid () dx code \\ -- edited for privacy

-- buiild table for condition 2 BMI measure
create table o_c2_bmi as (
select
    distinct ptid,
    obs_result
from
     obs_bmi
where
    obs_result >= 27 );

select count(1), count(distinct ptid) from o_c2_bmi;

select * from o_c2_bmi where obs_result < 27;
--0 good!

-- build ref table for comorbid dx codes
create table o_c2_dx_ref as (
select
        'ICD9' as code_type,
        code,
        replace(code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd9_diag_ref_table
    where
        replace(code,'.') like '401%'
        or replace(code,'.') = '2724'
        or replace(code,'.') = '2722'
        or replace(code,'.') = '25092'
        or replace(code,'.') = '2509'
        or replace(code,'.') = '25082'
        or replace(code,'.') = '2508'
        or replace(code,'.') = '25072'
        or replace(code,'.') = '2507'
        or replace(code,'.') = '25062'
        or replace(code,'.') = '2506'
        or replace(code,'.') = '25052'
        or replace(code,'.') = '2505'
        or replace(code,'.') = '25042'
        or replace(code,'.') = '2504'
        or replace(code,'.') = '25032'
        or replace(code,'.') = '2503'
        or replace(code,'.') = '25022'
        or replace(code,'.') = '2502'
        or replace(code,'.') = '25012'
        or replace(code,'.') = '2501'
        or replace(code,'.') = '25002'
        or replace(code,'.') = '250'

union

    select
        'ICD10' as code_type,
        diagnosis_code as code,
        replace(diagnosis_code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd10_diag_ref_table
    where
        replace(diagnosis_code,'.') like 'I10%'
        or replace(diagnosis_code,'.') like 'E11%'
        or replace(diagnosis_code,'.') = 'E785'
        or replace(diagnosis_code,'.') = 'E782' );

select * from o_c2_dx_ref;

-- build dx table for only patients with comorbid
create table c2_dx_pt_base as
    select
        a.ptid,
        a.diagnosis_cd,
        a.diagnosis_cd_type
    from
        production.diag_table a,
        o_c2_dx_ref b
    where
        a.diagnosis_cd = b.code_no_decimal
        and a.diagnosis_cd_type = b.code_type
        and a.diagnosis_status = 'Diagnosis of';

select count(1), count(distinct ptid) from c2_dx_pt_base;

-- build table for pts with 27+ and in comorbid table
create table o_c2 as(
select
    distinct a.ptid
from
    (select distinct ptid from o_c2_bmi) a,
    (select distinct ptid from c2_dx_pt_base) b
where
    a.ptid=b.ptid
);

select count(1), count(distinct ptid) from o_c2;

-- // Condition 3: o dx code \\ --

-- build condition 3 dx ref table
create table o_c3_dx_ref as (
select
        'ICD9' as code_type,
        code,
        replace(code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd9_diag_ref_table
    where
        replace(code,'.') = '27800'
        or replace(code,'.') = '27801'
        or replace(code,'.') = '27803'
        or replace(code,'.') = 'V8530'
        or replace(code,'.') = 'V8531'
        or replace(code,'.') = 'V8532'
        or replace(code,'.') = 'V8533'
        or replace(code,'.') = 'V8534'
        or replace(code,'.') = 'V8535'
        or replace(code,'.') = 'V8536'
        or replace(code,'.') = 'V8537'
        or replace(code,'.') = 'V8538'
        or replace(code,'.') = 'V8539'
        or replace(code,'.') = 'V8541'
        or replace(code,'.') = 'V8542'
        or replace(code,'.') = 'V8543'
        or replace(code,'.') = 'V8544'
        or replace(code,'.') = 'V8545'

union

    select
        'ICD10' as code_type,
        diagnosis_code as code,
        replace(diagnosis_code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd10_diag_ref_table
    where
        replace(diagnosis_code,'.') = 'E6609'
        or replace(diagnosis_code,'.') = 'E661'
        or replace(diagnosis_code,'.') = 'E662'
        or replace(diagnosis_code,'.') = 'E668'
        or replace(diagnosis_code,'.') = 'E669'
        or replace(diagnosis_code,'.') = 'Z6830'
        or replace(diagnosis_code,'.') = 'Z6831'
        or replace(diagnosis_code,'.') = 'Z6832'
        or replace(diagnosis_code,'.') = 'Z6833'
        or replace(diagnosis_code,'.') = 'Z6834'
        or replace(diagnosis_code,'.') = 'Z6835'
        or replace(diagnosis_code,'.') = 'Z6836'
        or replace(diagnosis_code,'.') = 'Z6837'
        or replace(diagnosis_code,'.') = 'Z6838'
        or replace(diagnosis_code,'.') = 'Z6839'
        or replace(diagnosis_code,'.') = 'Z6841'
        or replace(diagnosis_code,'.') = 'Z6842'
        or replace(diagnosis_code,'.') = 'Z6843'
        or replace(diagnosis_code,'.') = 'Z6844'
        or replace(diagnosis_code,'.') = 'Z6845'
        or replace(diagnosis_code,'.') = 'E6601');

select * from o_C3_DX_REF;

select count(1), count(distinct code) from o_C3_DX_REF;


select code_type, count(distinct code) from o_C3_DX_REF group by code_type;


-- build dx table for only patients with condition 3 dx codes
create table c3_dx_pt_base as
    select
        a.ptid,
        a.diagnosis_cd,
        a.diagnosis_cd_type
    from
        production.diag_table a,
        o_C3_DX_REF b
    where
        a.diagnosis_cd = b.code_no_decimal
        and a.diagnosis_cd_type = b.code_type;

select count(1), count(distinct ptid), count(distinct diagnosis_cd) from c3_dx_pt_base;


create table o_c3 as (
select distinct ptid from c3_dx_pt_base) ;

select count(1), count(distinct ptid) from o_c3;

-- // Condition 4: Rx \\ --

create table c4_rx_ref as (
select
    bn,
    ln,
    gnn60,
    ndc
from
    data_warehouse.stg_dcc_ndc_raw
where
    ndc = 169280015);

select '--' || count(1), count(distinct ndc) from c4_rx_ref;

-- pull rx pt base
create table o_c4 as (
    (select
        a.ptid,
        a.ndc,
        a.drug_name
    from
        production.rx_presc_table a,
        c4_rx_ref b
    where
        a.ndc = b.ndc)
union
    (select
        a.ptid,
        a.ndc,
        a.drug_name
    from
        production.rx_adm_table a,
        c4_rx_ref b
    where
        a.ndc = b.ndc) );

select count(1), count(distinct ptid) from o_c4 ;

-- // o Patient Base \\ --

create table o_pt_base as (
select distinct ptid from o_c1
UNION
select distinct ptid from o_c2
UNION
select distinct ptid from o_c3
UNION
select distinct ptid from o_c4 ) ;

select count(1), count(distinct ptid) from o_pt_base;

/*  2. n */
-- 2 conditions:
--      1. Exact dx codes
--      2. Exact and wildcard px codes


-- // Condition 1: Exact dx codes \\ --
create table n_dx_ref as (
select
        'ICD9' as code_type,
        code,
        replace(code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd9_diag_ref_table
    where
       replace(code,'.') = '5718'
       or replace(code,'.') = '5719'

union

    select
        'ICD10' as code_type,
        diagnosis_code as code,
        replace(diagnosis_code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd10_diag_ref_table
    where
        replace(diagnosis_code,'.') = 'K7581'
        or replace(diagnosis_code,'.') = 'K760'
        or replace(diagnosis_code,'.') = 'R932' );

select count(1), count(distinct code) from n_dx_ref;

select code_type, count(distinct code) from n_dx_ref group by code_type;

-- search for codes in dx table
create table n_dx_pt_base as (
    select
        a.ptid,
        a.diagnosis_cd,
        a.diagnosis_cd_type
    from
        production.diag_table a,
        n_dx_ref b
    where
        a.diagnosis_cd = b.code_no_decimal
        and a.diagnosis_cd_type = b.code_type) ;


select count(1), count(distinct ptid), count(distinct diagnosis_cd) from n_dx_pt_base;


-- // Condition 2: Exact and wildcard px codes \\ --
create table n_px_ref as (
    select
        code code,
        'ICD9' code_type,
        long_description descript
    from
        data_warehouse.icd9_px_ref_table
    where
        code like '50.1%'
union
    select
        procedure_code code,
        'ICD10' code_type,
        long_description descrip
    from
        data_warehouse.icd10_px_ref_table
    where
        procedure_code like 'BF25%'
        or procedure_code like 'BF35%'
        or procedure_code like 'BF36%'
        or procedure_code like 'BF45%'
        or procedure_code like 'BF46%'
        or procedure_code like '0FB0%'
        or procedure_code like '0FB1%'
        or procedure_code like '0BF2%'
union
    select
        concept_code code,
        'CPT4' code_type,
        concept_name descript
    from
      data_warehouse.cpt_ref_table
    where
        concept_code = '74181'
        or concept_code = '74182'
        or concept_code = '74183'
        or concept_code = '76700'
        or concept_code = '76705'
        or concept_code = '74160'
        or concept_code = '74150'
        or concept_code = '74170'
        or concept_code = '91200'
        or concept_code = '84450'
        or concept_code = '84460'
        or concept_code = '80076'
union
    select
        concept_code code,
        'HCPCS' code_type,
        concept_name descript
    from
      data_warehouse.cpt_ref_table
    where
        concept_code = '47000'
        or concept_code = '47001');

select * from n_px_ref;
select count(1), count(distinct code) from n_px_ref;
/* -- some codes have multi descriptions
        but not an issue. when we join on proc_table we'll use code_type to align correctly -- */

select '--' || code_type, count(distinct code) from n_px_ref group by code_type;

create table n_px_pt_base as (
    select
        a.ptid,
        a.proc_code,
        a.proc_code_type,
        a.proc_desc
    from
        production.proc_table a,
        n_px_ref b
    where
        a.proc_code = b.code
        and a.proc_code_type = b.code_type );

select count(1), count(distinct ptid), count(distinct proc_code) from n_px_pt_base;

-- // n Patient Base \\ --

create table n_pt_base as (
select distinct ptid from  n_dx_pt_base
UNION
select distinct ptid from  n_px_pt_base);

select count(1), count(distinct ptid) from n_pt_base ;

/*  3. i */
-- Conditions:
--  1. Wildcard & exact dx codes

-- build ref table
create table i_dx_ref as (
select
        'ICD9' as code_type,
        code,
        replace(code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd9_diag_ref_table
    where
    -- wildcard
        replace(code,'.') like '555%'
        or replace(code,'.') like '556%'
        or replace(code,'.') like '560%'
        or replace(code,'.') like '565%'
        or replace(code,'.') like '569%'
    -- exact
        or replace(code,'.') = '566'
        or replace(code,'.') = '7131'

union

    select
        'ICD10' as code_type,
        diagnosis_code as code,
        replace(diagnosis_code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd10_diag_ref_table
    where
        replace(diagnosis_code,'.') like 'K50%'
        or replace(diagnosis_code,'.') like 'K51%'
        or replace(diagnosis_code,'.') like 'K56%'
        or replace(diagnosis_code,'.') like 'K60%'
        or replace(diagnosis_code,'.') like 'K61%'
        or replace(diagnosis_code,'.') like 'K62%'
        or replace(diagnosis_code,'.') like 'K63%');

select count(1), count(distinct code) from i_dx_ref;

select code_type, count(distinct code) from i_dx_ref group by code_type;


-- search for codes in dx table
create table i_dx_pt_base as (
    select
        a.ptid,
        a.diagnosis_cd,
        a.diagnosis_cd_type
    from
        production.diag_table a,
        i_dx_ref b
    where
        a.diagnosis_cd = b.code_no_decimal
        and a.diagnosis_cd_type = b.code_type
        and a.diagnosis_status = 'Diagnosis of' ) ;

select count(1), count(distinct ptid), count(distinct diagnosis_cd) from i_dx_pt_base;

-- // i Patient Base \\ --
create table i_pt_base as (
select distinct ptid from  i_dx_pt_base);

select count(1), count(distinct ptid) from i_pt_base ;

/* d */
-- Conditions:
--  Wildcard dx codes

-- build ref table
create table d_dx_ref as (
select
        'ICD9' as code_type,
        code,
        replace(code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd9_diag_ref_table
    where
    -- wildcard
        replace(code,'.') like '249%'
        or replace(code,'.') like '250%'

union

    select
        'ICD10' as code_type,
        diagnosis_code as code,
        replace(diagnosis_code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd10_diag_ref_table
    where
        replace(diagnosis_code,'.') like 'E08%'
        or replace(diagnosis_code,'.') like 'E09%'
        or replace(diagnosis_code,'.') like 'E10%'
        or replace(diagnosis_code,'.') like 'E11%'
        or replace(diagnosis_code,'.') like 'E12%'
        or replace(diagnosis_code,'.') like 'E13%');

select count(1), count(distinct code) from d_dx_ref;

select code_type, count(distinct code) from d_dx_ref group by code_type;


-- search for codes in dx table
create table d_dx_pt_base as (
    select
        a.ptid,
        a.diagnosis_cd,
        a.diagnosis_cd_type
    from
        production.diag_table a,
        d_dx_ref b
    where
        a.diagnosis_cd = b.code_no_decimal
        and a.diagnosis_cd_type = b.code_type) ;

select count(1), count(distinct ptid), count(distinct diagnosis_cd) from d_dx_pt_base;

-- // d Patient Base \\ --
select * from d_pt_base;
create table d_pt_base as (
select distinct ptid from  d_dx_pt_base);

select count(1), count(distinct ptid) from d_pt_base ;


/*  5. ck */
-- Conditions:
--  1. Exact & wildcard dx codes

create table ck_dx_import (
    code varchar(100),
    code_type varchar(100),
    note varchar(1000) ) ;

-- want to capture codes with trailing 0s as well as those without
select * from data_warehouse.icd9_diag_ref_table where code like '274.1%';
select * from data_warehouse.icd10_diag_ref_table where diagnosis_code like 'Q61%';
-- trailing 0 issue only efefcts ICD9s


select * from ck_dx_import;
select code_type, count(1), count(distinct code) from ck_dx_import group by code_type;


-- build ref table
create table ck_dx_ref as (
select
        'ICD9' as code_type,
        code,
        replace(code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd9_diag_ref_table
    where
        replace(code,'.') in (select replace(code,'.') from ck_dx_import where code_type = 'ICD9')
        -- wildcarding these because client wants to capture trailing 0s
        or replace(code,'.') like '2504%'
        or replace(code,'.') like '2714%'
        or replace(code,'.') like '2741%'
        or replace(code,'.') like '403%'
        or replace(code,'.') like '4031%'
        or replace(code,'.') like '4039%'
        or replace(code,'.') like '404%'
        or replace(code,'.') like '4041%'
        or replace(code,'.') like '4049%'
        or replace(code,'.') like '4401%'
        or replace(code,'.') like '4421%'
        or replace(code,'.') like '4473%'
        or replace(code,'.') like '5724%'
        or replace(code,'.') like '580%'
        or replace(code,'.') like '5804%'
        or replace(code,'.') like '5809%'
        or replace(code,'.') like '581%'
        or replace(code,'.') like '5811%'
        or replace(code,'.') like '5812%'
        or replace(code,'.') like '5813%'
        or replace(code,'.') like '5819%'
        or replace(code,'.') like '582%'
        or replace(code,'.') like '5821%'
        or replace(code,'.') like '5822%'
        or replace(code,'.') like '5824%'
        or replace(code,'.') like '5829%'
        or replace(code,'.') like '583%'
        or replace(code,'.') like '5831%'
        or replace(code,'.') like '5832%'
        or replace(code,'.') like '5834%'
        or replace(code,'.') like '5836%'
        or replace(code,'.') like '5837%'
        or replace(code,'.') like '5839%'
        or replace(code,'.') like '5845%'
        or replace(code,'.') like '5846%'
        or replace(code,'.') like '5847%'
        or replace(code,'.') like '5848%'
        or replace(code,'.') like '5849%'
        or replace(code,'.') like '5851%'
        or replace(code,'.') like '5852%'
        or replace(code,'.') like '5853%'
        or replace(code,'.') like '5854%'
        or replace(code,'.') like '5859%'
        or replace(code,'.') like '586%'
        or replace(code,'.') like '587%'
        or replace(code,'.') like '588%'
        or replace(code,'.') like '5881%'
        or replace(code,'.') like '5889%'
        or replace(code,'.') like '591%'
        or replace(code,'.') like '6421%'
        or replace(code,'.') like '6462%'
        or replace(code,'.') like '7532%'
        or replace(code,'.') like '7944%'
        or replace(code,'.') like '5855%'
        or replace(code,'.') like '5856%'


union

    select
        'ICD10' as code_type,
        diagnosis_code as code,
        replace(diagnosis_code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd10_diag_ref_table
    where
        replace(diagnosis_code,'.') in (select replace(code,'.') from ck_dx_import where code_type = 'ICD10') ) ;

select * from ck_dx_ref;
select count(1), count(distinct code) from ck_dx_ref;

select code_type, count(1), count(distinct code) from ck_dx_ref group by code_type;


-- search for codes in dx table
create table ck_dx_pt_base as (
    select
        a.ptid,
        a.diagnosis_cd,
        a.diagnosis_cd_type
    from
        production.diag_table a,
        ck_dx_ref b
    where
        a.diagnosis_cd = b.code_no_decimal
        and a.diagnosis_cd_type = b.code_type) ;

select count(1), count(distinct ptid), count(distinct diagnosis_cd) from ck_dx_pt_base;

-- // ck Patient Base \\ --

create table ck_pt_base as (
select distinct ptid from  ck_dx_pt_base);

select count(1), count(distinct ptid) from ck_pt_base ;


/*  cv */
-- Conditions:
--  1. Exact & wildcard dx codes
--  2. Exact px codes

-- create table for imports, will contain px and dx codes
create table cv_dx_import (
    code varchar(100),
    code_type varchar(100),
    tbl varchar(10),
    note varchar(1000),
    subsection varchar(100) );


select * from cv_dx_import;
select tbl, code_type, count(1), count(distinct code) from cv_dx_import group by tbl, code_type;

-- build ref table
create table cv_dx_ref as (
select
        'ICD9' as code_type,
        code,
        replace(code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd9_diag_ref_table
    where
        replace(code,'.') in (select replace(code,'.') from cv_dx_import where tbl = 'Dx' and code_type = 'ICD9')
        -- wildcards --
        or replace(code,'.') like '443%'

union

    select
        'ICD10' as code_type,
        diagnosis_code as code,
        replace(diagnosis_code,'.') as code_no_decimal,
        short_description,
        long_description
    from
        data_warehouse.icd10_diag_ref_table
    where
        replace(diagnosis_code,'.') in (select replace(code,'.') from cv_dx_import where tbl = 'Dx' and code_type = 'ICD10')
        -- wildcards --
        or replace(diagnosis_code,'.') like 'I21A%'
        or replace(diagnosis_code,'.') like 'I73%') ;

select * from cv_dx_ref ;
select count(1), count(distinct code) from cv_dx_ref ;

select code_type, count(1), count(distinct code) from cv_dx_ref group by code_type;

-- search for codes in dx table
create table cv_dx_pt_base as (
    select
        a.ptid,
        a.diagnosis_cd,
        a.diagnosis_cd_type
    from
        production.diag_table a,
        cv_dx_ref b
    where
        a.diagnosis_cd = b.code_no_decimal
        and a.diagnosis_cd_type = b.code_type) ;

select count(1), count(distinct ptid), count(distinct diagnosis_cd) from cv_dx_pt_base;



-- Exact px codes --
select count(1) from cv_dx_import
    where tbl = 'Px';

create table cv_px_ref as (
    select
        code code,
        'ICD9' code_type,
        long_description descript
    from
        data_warehouse.icd9_px_ref_table
    where
        replace(code,'.','') in (select code from cv_dx_import where code_type = 'ICD9' and tbl='Px')
union
    select
        procedure_code code,
        'ICD10' code_type,
        long_description descrip
    from
        data_warehouse.icd10_px_ref_table
    where
        procedure_code in (select code from cv_dx_import where code_type = 'ICD10' and tbl='Px')
union
    select
        concept_code code,
        'CPT4' code_type,
        concept_name descript
    from
      data_warehouse.cpt_ref_table
    where
        concept_code in (select code from cv_dx_import where code_type = 'CPT' and tbl='Px')
);

select count(1), count(distinct code) from cv_px_ref ;

create table cv_px_pt_base as (
    select
        a.ptid,
        a.proc_code,
        a.proc_code_type,
        a.proc_desc
    from
        production.proc_table a,
        cv_px_ref b
    where
        a.proc_code = b.code
        and a.proc_code_type = b.code_type );

select count(1), count(distinct ptid), count(distinct proc_code) from cv_px_pt_base ;



-- // cv Patient Base \\ --
create table cv_pt_base as (
select distinct ptid from  cv_dx_pt_base
union
select distinct ptid from cv_px_pt_base
);

select count(1), count(distinct ptid) from cv_pt_base ;


/*  7. FINAL PATIENT BASE  */
create table pt_base as (
select distinct ptid from o_pt_base
union
select distinct ptid from n_pt_base
union
select distinct ptid from i_pt_base
union
select distinct ptid from d_pt_base
union
select distinct ptid from ck_pt_base
union
select distinct ptid from cv_pt_base );

select count(1), count(distinct ptid) from pt_base;

alter table pt_base rename to pt_base_table;

------------------------------------------------------------------------------------------------------------------------------
----------------------------------- CUSTOM PT TABLE -----------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
create table pt_flag1 as(
select distinct ptid, 'o' as cohort from o_pt_base  -- truncated '' for privacy
union all
select distinct ptid, 'n' as cohort from n_pt_base  -- truncated '' for privacy
union all
select distinct ptid, 'i' as cohort from i_pt_base  -- truncated '' for privacy
union all
select distinct ptid, 'd' as cohort from d_pt_base  -- truncated '' for privacy
union all
select distinct ptid, 'ck' as cohort from ck_pt_base  -- truncated '' for privacy
union all
select distinct ptid, 'cv' as cohort from cv_pt_base);  -- truncated '' for privacy

select count(1), count(distinct ptid), count(distinct cohort) from pt_flag1;

select '--' || cohort, count(1), count(distinct ptid) from pt_flag1 group by cohort;


create table pt_flag2 as (
select
    ptid,
    case when cohort = 'o' then 1 else 0 end c_o, -- truncated '' for privacy
    case when cohort = 'n' then 1 else 0 end c_n,  -- truncated '' for privacy
    case when cohort = 'i' then 1 else 0 end c_i,  -- truncated '' for privacy
    case when cohort = 'd' then 1 else 0 end c_d,  -- truncated '' for privacy
    case when cohort = 'ck' then 1 else 0 end c_ck,  -- truncated '' for privacy
    case when cohort = 'cv' then 1 else 0 end c_cv  -- truncated '' for privacy
from
    pt_flag1);

create table pt_flag3 as(
select
    distinct ptid,
    sum(c_o) c_o,
    sum(c_n) c_n,
    sum(c_i) c_i,
    sum(c_d) c_d,
    sum(c_ck) c_ck,
    sum(c_cv) c_cv
from
    pt_flag2
group by
    ptid );

select * from pt_flag3;
select count(1), count(distinct ptid) from pt_flag3 ;
-- 37553326	37553326

select
    '-- o ' || sum(c_o),
    '-- n ' || sum(c_n) c_n,
    '-- i ' || sum(c_i) c_i,
    '-- d ' || sum(c_d) c_d,
    '-- ck ' || sum(c_ck) c_ck,
    '-- cv ' || sum(c_cv) c_cv
from pt_flag3 ;

-- o 28043996
-- n 11061375
-- i 4592934
-- d 7207442
-- ck 7148073
-- cv 8378594

-- create custom patient table
--select * from production.pt_table;

create table pt_table as (
select
    a.PTID,
-- omitted for privacy
from
    production.pt_table a,
    pt_flag3 b
where
    a.ptid = b.ptid );

select * from pt_table;
select count(1), count(distinct ptid) from pt_table;
