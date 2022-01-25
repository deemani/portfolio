/* Proc Codes */
-- import proc codes provided by client
create table proc_codes (
    cat varchar(100),
    anatomy varchar(100),
    treatment varchar(100),
    code_type varchar(25),
    code varchar(100),
    descrip varchar(250),
    note varchar(100) );


select * from proc_codes;
select count(1), count(distinct code) from proc_codes;
--168	168

select '--' || code_type, count(1) from proc_codes group by code_type;
--ICD10	156
--CPT4	2
--ICD9	10

-- run codes through reference tables
create table px_ref as (
    select
        code code,
        'ICD9' code_type,
        long_description descrip
    from
        data_warehouse.icd9_ref_table
    where
        replace(code,'.') in (select code from proc_codes where code_type = 'ICD9')
union
    select
        procedure_code code,
        'ICD10' code_type,
        long_description descrip
    from
        data_warehouse.icd10_ref_table
    where
        replace(procedure_code,'.') in (select code from proc_codes where code_type = 'ICD10')
union
    select
        concept_code code,
        'CPT4' code_type,
        concept_name descrip
    from
        data_warehouse.cpt_ref_table
    where
        concept_code in (select code from proc_codes where code_type = 'CPT4'));

select * from px_ref;
select count(1) from px_ref;
--172
-- 4 extra codes


select code_type, count(1), count(distinct code) from px_ref group by code_type;
--ICD10	156	156
--CPT4	6	2 <<<< CPT pulled in 4 extra codes but won't mess with output
--ICD9	10	10

--drop table px_table purge;
create table px_table as (
select
    a.*
from
    production.proc_table a,
    px_ref b
where
    a.proc_code = b.code
    and a.proc_code_type = b.code_type) ;

select count(1), count(distinct ptid), count(distinct proc_code) from px_table;
--83480	48229	82


-- which provided codes did not pull? 96 codes missing
drop table px_missing;
create table px_missing as (
select
    code
from
    px_ref
where
    code not in (select distinct proc_code from px_table) ) ;

select * from px_missing;
select count(1) from px_missing;
--86 provided codes missing

-- checking to make sure codes are not in px table
create table px_missing_check as (
select
    a.ptid,
    a.encid,
    a.proc_date,
    a.proc_code,
    a.proc_desc,
    a.proc_code_type
from
    production.proc_final a,
    px_missing b
where
    a.proc_code = b.code );

select count(1) from px_missing_check;
--0, none are in the px table


select count(1), count(distinct ptid), count(distinct groupid), count(distinct proc_code) from px_table;
--83480	48229	39	82

/* Institution Data */
create table source_groups (
    sourceid varchar(25),
    groupid varchar(25) );

select * from source_groups;
select count(1), count(distinct sourceid), count(distinct groupid) from source_groups;
--54	31	31

-- filter down on hgroups provided by CS
create table px_table2 as (
select * from px_table where groupid in (select groupid from source_groups));

select count(1), count(distinct ptid), count(distinct proc_code), count(distinct groupid) from px_table2;
--34111	22721	66  18

select * from px_table2;

select proc_code_type, count(distinct proc_code) from px_table2 group by proc_code_type;
--ICD10	54
--CPT4	2
--ICD9	10

/* client Patient List */

-- load patient list (swapped out institution locations with sourceid  & hgroup in excel)
drop table client_data_table purge;
create table client_data_table (
    client_id varchar(100),
    proc_date varchar(10),
    proc_time varchar(25),
    sourceid varchar(10),
    groupid varchar(25),
    proc_type varchar(1000),
    tissue_type varchar(100) );

select * from client_data_table;
select count(1), count(distinct client_id), count(distinct groupid), count(distinct sourceid) from client_data_table;
--1020	1020	13	13

-- how many records provided by client have group matches?
select count(1), count(distinct client_id), count(distinct groupid), count(distinct sourceid) from client_data_table where sourceid is not null;
--113	113	13	13

-- convert proc_date field to match proc_table date format
update client_data_table
set proc_date = to_char(to_date(proc_date, 'MM/DD/YY'),'MM-DD-YYYY');
select * from client_data_table;

-- filter down on client_ids with sourceids
create table client_data_table2 as (
select * from client_data_table where sourceid is not null  ) ;

select count(1), count(distinct client_id), count(distinct groupid), count(distinct sourceid) from client_data_table2;
--113	113	13	13

select count(1), count(distinct client_id), count(distinct groupid), count(distinct sourceid) from client_data_table2 where sourceid is not null;
--113	113	13	13


/* Match client patients to Production proc data */
select * from client_data_table2;
select * from px_table2;

select distinct groupid from client_data_table2 where groupid in (select distinct groupid from px_table2);
-- 6 groups in client list are also in proc table

drop table matched_data purge;
create table matched_data as (
select
    a.*,
    b.proc_date pan_proc_date,
    b.ptid,
    b.encid,
    b.proc_code,
    b.proc_code_type,
    b.sourceid px_sourceid,
    b.groupid px_groupid
from
    client_data_table2 a,
    px_table2 b
where
    (a.groupid = b.groupid
    AND a.proc_date = b.proc_date)

    -- adding extra conditions to capture 4 days after proc_date

    OR
    (a.groupid = b.groupid
    AND to_char(to_date(a.proc_date, 'MM-DD-YYYY')+1, 'MM-DD-YYYY') = b.proc_date)
    OR
    (a.groupid = b.groupid
    AND to_char(to_date(a.proc_date, 'MM-DD-YYYY')+2, 'MM-DD-YYYY') = b.proc_date)
    OR
    (a.groupid = b.groupid
    AND to_char(to_date(a.proc_date, 'MM-DD-YYYY')+3, 'MM-DD-YYYY') = b.proc_date)
    OR
    (a.groupid = b.groupid
    AND to_char(to_date(a.proc_date, 'MM-DD-YYYY')+4, 'MM-DD-YYYY') = b.proc_date)
    OR
    (a.groupid = b.groupid
    AND to_char(to_date(a.proc_date, 'MM-DD-YYYY')+5, 'MM-DD-YYYY') = b.proc_date)
);

select * from matched_data;
select count(1), count(distinct client_id), count(distinct ptid), count(distinct groupid) from matched_data;
--70	13	25	5
-- more ptids than client_ids because we don't know which pt is exactly who client called

-- create final table
drop table final_deliverable purge;
create table final_deliverable as (
select DISTINCT
    client_id,
    proc_date,
    proc_time,
    proc_type,
    tissue_type,
    ptid
from
    matched_data);

select count(1), count(distinct ptid) from final_deliverable ;
--29	25
-- matched roughly 3% of records provided by client which is expected

select '--' || tissue_type, count(1), count(distinct ptid) from final_deliverable group by tissue_type;
--Bone	29	25

select * from final_deliverable;
