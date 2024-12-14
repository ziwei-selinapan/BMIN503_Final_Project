/* ESRD Valves - AVR (paper 1) */
/* 05-30-2024 */
/* PI: Chase Brown */
/* Analyst: Selina Pan */

libname Brown "/project/Brown_Cardiac_Surgery/Data/";
libname temp "/project/Brown_Cardiac_Surgery/Data/Temp/";
libname Denom "/origdata/CMS_shared/Denom100/";
libname Medpar "/origdata/CMS_shared/Medpar100/CY";

*Cohort with both AVR, MVR, TAVR and TMVR;
proc contents data=temp.ESRD_all_0524;run; * N = 21,528, Corrected Diagnosis;
proc contents data=temp.AVR_all_0606;run; 
proc contents data=Brown.Medpar_PRCDR_DT;run; 
proc contents data=Brown.Denom_ESRD_09_19;run; 
proc contents data=temp.AVR_post_pcd_0607;run;
proc contents data=temp.AVR_outcome_indicators_0628;run;
proc contents data=Brown.medpar2009_2020;run;
proc print data=Brown.medpar2009_2020(obs=100);

/* data test2009; */
/* set Brown.medpar2009_2020; */
/* monthtest=month(ADMSNDT); */
/* yeartest=year(ADMSNDT); */
/* if yeartest = 2009 and MEDPAR_YR_NUM = 2009; */
/* run; */
/* proc sort data=test2009 out=test2009; */
/* by ADMSNDT; */
/* run; */

proc sort data=temp.ESRD_all_0524 out=temp.ESRD_all_0524;
by BENE_ID ADMSNDT;
run;

proc sort data=test out=test;
by BENE_ID ADMSNDT;
run;

data unique_N_patients;
set temp.ESRD_all_0524;
by BENE_ID;
if first.BENE_ID;
run; 
data unique_bene_0601;
set unique_N_patients;
keep BENE_ID;
run;


/* * Update Diagnosis 11-25: ; */
/* proc freq data = temp.ESRD_all_0524; */
/* table DGNS_CD11; */
/* run; */
/*  */
/* data ESRD_all_0524; */
/* set temp.ESRD_all_0524; */
/* drop DGNS_CD:; */
/* run; */
/*  */
/* data Medpar_DGNS; */
/* set Brown.Medpar_PRCDR_DT; */
/* drop PRCDR_CD: PRCDR_DT: ; */
/* run; */
/*  */
/* proc sql; */
/*   create table temp.ESRD_all_0524 as */
/*   select A.*, B.* */
/*   from ESRD_all_0524 A */
/*   inner join Medpar_DGNS B */
/*   on A.BENE_ID_medpar = B.BENE_ID_medpar and A.ADMSNDT_medpar = B.ADMSNDT_medpar; */
/* quit; */

/* data ESRD_AVR_0530; */
/* set temp.ESRD_all_0524; */
/* if valve_type = 1 | valve_type = 2 | valve_type = 5 ; */
/* run; *N = 16,198; */

data medpar2009_2020;
set Brown.medpar2009_2020;
drop DGNS_CD: PRCDR_CD: ;
run;

/* Merge with procedure date from raw MedPAR: */
proc sql;
  create table temp0521 as
  select A.*, B.*
  from medpar2009_2020 A
  inner join Brown.Medpar_PRCDR_DT B
  on A.BENE_ID = B.BENE_ID_medpar and A.ADMSNDT = B.ADMSNDT_medpar;
quit; *N = 194,537,506;


*Define inclusion Criteria: AVR;
data temp0521_1;
set temp0521;
DGNS_CD25 = DGNS_25_CD;

array dgn[25] DGNS_CD01 DGNS_CD010 DGNS_CD02 -- DGNS_CD09 DGNS_CD11 -- DGNS_CD24 DGNS_CD25; 
array prc[25] PRCDR_CD1 -- PRCDR_CD6 PRCDR_CD7 -- PRCDR_CD25; 
array date[25]  PRCDR_DT1 -- PRCDR_DT6 PRCDR_DT7 -- PRCDR_DT25;

Mechanical_AVR = 0;
Bioprosthetic_AVR = 0;
TAVR = 0;
Procedure_date = 0;

do i = 1 to 25;

*Mark mechanical & Bioprosthetic AVR & TAVR procedures;
    if prc[i] in ("3522", "02RF0JZ") then do;
        Mechanical_AVR = 1;
        Procedure_date = date[i];
    end;
    if prc[i] in ("3521","02RF07Z","02RF08Z","02RF0KZ") then do;
        Bioprosthetic_AVR = 1;
        Procedure_date = date[i];
    end;
    if substr(prc[i], 1, 5) in ("02RF3","02RF4") then do;
        TAVR = 1;
        Procedure_date = date[i];
    end;
    if substr(prc[i], 1, 4) in ("3505","3506") then do;
        TAVR = 1;
        Procedure_date = date[i];
    end;
    
end;
drop i;
run;


data temp.temp0606;
set temp0521_1;
if (Mechanical_AVR = 0 & Bioprosthetic_AVR = 0 & TAVR = 0 ) then delete;
run; *757,632;


data temp0606_1;
set temp.temp0606;

array dgn[25] DGNS_CD01 DGNS_CD010 DGNS_CD02 -- DGNS_CD09 DGNS_CD11 -- DGNS_CD24 DGNS_CD25; 
array prc[25] PRCDR_CD1 -- PRCDR_CD6 PRCDR_CD7 -- PRCDR_CD25; 

multiple_valves = 0;
if Mechanical_AVR + Bioprosthetic_AVR + TAVR > 1 then multiple_valves = 1;

exclu_comorbidity = 0;
do i = 1 to 25;

*Mark concomitant procedures that needs to be excluded;
    if prc[i] in ("3523", "3524", "3510", "3511", "3513", "3514", "3527", "3528", 
    "3507", "3508", "3525", "3526", "3804", "3814", "3834", "3844", "3845", "3864", 
    "3971", "3973", "3978", "3509", "3520", "3596", "336", "3751", "3752", "375", 
    "3753", "3754", "3755", "3760", "3762", "3763", "3765", "3766", "3768", 
    "02RG0JZ", "02RG07Z", "02RG08Z", "02RG0KZ", "02QF", "02QH", "02WJ", "02RH", 
    "02RJ", "02RX", "02RW", "02QX", "02QR", "02VX", "02VW", "02HX", "02HW", "04R0", 
    "04Q0", "04V0", "04H0", "X2RF032", "02HA0QZ", "02HA0RJ", "02HA0RS", "02HA0RZ", 
    "02HA3QZ", "02HA3RJ", "02HA3RS", "02HA3RZ", "02HA4QZ", "02HA4RJ", "02HA4RS", 
    "02HA4RZ", "02RK07Z", "02RK08Z", "02RK0JZ", "02RK0KZ", "02RK47", "02RK47Z", 
    "02RK48Z", "02RK4JZ", "02RK4KZ", "02RL07Z", "02RL08Z", "02RL0JZ", "02RL0KZ", 
    "02RL47Z", "02RL48Z", "02RL4JZ", "02RL4KZ", "02UA0JZ", "02UA3JZ", "02UA4JZ", 
    "02WA0JZ", "02WA0QZ", "02WA3QZ", "02YA0Z0", "02YA0Z1", "02YA0Z2", "5A02116", 
    "5A0211D") then do;
        exclu_comorbidity = 1;
    end;
    if substr(prc[i], 1, 4) in ("3523", "3524", "3510", "3511", "3513", "3514", "3527", "3528", 
    "3507", "3508", "3525", "3526", "3804", "3814", "3834", "3844", "3845", "3864", 
    "3971", "3973", "3978", "3509", "3520", "3596", "336", "3751", "3752", "375", 
    "3753", "3754", "3755", "3760", "3762", "3763", "3765", "3766", "3768","02QF", 
    "02QH", "02WJ", "02RH", "02RJ", "02RX", "02RW", "02QX", "02QR", "02VX", "02VW", 
    "02HX", "02HW", "04R0", "04Q0", "04V0", "04H0") then do;
        exclu_comorbidity = 1;
    end;
    if substr(prc[i], 1, 3) in ("336","375") then do;
        exclu_comorbidity = 1;
    end;
    
    if dgn[i] in ("421", "4210", "4219", "4211", "4249", "42499", "42490", "42491", 
    "11281", "03642", "09884", "11404", "11515", "11594", "I33", "I330", "I339", 
    "I38", "I39", "A3951", "B376") then do;
        exclu_comorbidity = 1;
    end;
    if substr(dgn[i], 1, 4) in ("4210", "4219", "4211", "4249", "I330", "I339", "B376") then do;
        exclu_comorbidity = 1;
    end;
    if substr(dgn[i], 1, 3) in ("421", "I33" "I38", "I39") then do;
        exclu_comorbidity = 1;
    end;
end;
drop i;
run;

Data temp.valve_AVR_0606;
set temp0606_1;
if multiple_valves = 1 then delete;
if exclu_comorbidity = 1 then delete;
run; *663,092  662,355;


data Denominator2009_2019_new;
	set Denom.Dn100mod_2009 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MS_CD OREC CREC)
		Denom.Dn100mod_2010 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MS_CD OREC CREC)
		Denom.Dn100mod_2011 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MS_CD OREC CREC)
		Denom.Dn100mod_2012 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MS_CD OREC CREC)
		Denom.Dn100mod_2013 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MS_CD OREC CREC)
		Denom.Dn100mod_2014 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MS_CD OREC CREC)
		Denom.Dn100mod_2015 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MDCR_STATUS_CODE_: OREC CREC)
		Denom.Dn100mod_2016 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MDCR_STATUS_CODE_: OREC CREC)
		Denom.Dn100mod_2017 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MDCR_STATUS_CODE_: OREC CREC)
		Denom.Dn100mod_2018 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MDCR_STATUS_CODE_: OREC CREC)
		Denom.Dn100mod_2019 (keep = BENE_ID BENE_DOB DEATH_DT RFRNC_YR SEX RACE ESRD_IND MDCR_STATUS_CODE_: OREC CREC)
		; 
	rename BENE_ID = BENE_ID_denom;
run;

data Brown.Denom_ESRD_09_19;
set Denominator2009_2019_new;
if ESRD_IND = "Y";
run;


*Match MedPAR cohort (temp0409) with Denom;
proc sql;
    create table temp.AVR_merge_denom_0606 as
    select A.*, B.*
    from Brown.Denom_ESRD_09_19 A
    inner join temp.valve_AVR_0606 B
    on A.BENE_ID_denom = B.BENE_ID and a.RFRNC_YR = b.YEAR;
quit;*N = 20818   20793;


proc sql;
    create table temp.merge_denom_ESRD_prev_year as
    select A.*
    from temp.AVR_merge_denom_0606 A
    inner join Brown.Denom_ESRD_09_19 B
    on A.BENE_ID = B.BENE_ID_denom and a.YEAR = b.RFRNC_YR + 1;
quit; *14943  14931;


proc sql;
create table temp.merge_denom_ESRD_no_prev_year as 
((select * from temp.AVR_merge_denom_0606) 
except (select * from temp.merge_denom_ESRD_prev_year));
quit; * 5872  5859;


proc sql;
create table temp.merge_denom_ESRD_no_prev_year as
SELECT *, 
YEAR(ADMSNDT - 180) as adm_year_6mo_b4, 
MONTH(ADMSNDT - 180) as adm_mo_6mo_b4 
FROM temp.merge_denom_ESRD_no_prev_year;
quit;

data Denom_either_mo;
set Denominator2009_2019_new;

array mdcr {12} MDCR_STATUS_CODE_01-MDCR_STATUS_CODE_12;

flag = 0;
do i = 1 to 12;
    if mdcr[i] in ("11", "21", "31") then do;
        flag = 1;
    end;
end;

if flag = 1;

drop i;
drop flag;

run; *: 2945214;

*finding patients who does not have a previous year ESRD indicator
but has a previous 6 months ESRD indicator.
This montly indicator variable only exist from 2015 to 2019;
proc sql;
    create table temp.ESRD_no_prev_year_but_prev_6mo as
    select A.*
    from temp.merge_denom_ESRD_no_prev_year A
    inner join Denom_either_mo B
    on A.BENE_ID_denom = B.BENE_ID_denom 
    and a.adm_year_6mo_b4 = b.RFRNC_YR
    and (
    (a.adm_mo_6mo_b4 = 1 and B.MDCR_STATUS_CODE_01 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 2 and B.MDCR_STATUS_CODE_02 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 3 and B.MDCR_STATUS_CODE_03 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 4 and B.MDCR_STATUS_CODE_04 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 5 and B.MDCR_STATUS_CODE_05 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 6 and B.MDCR_STATUS_CODE_06 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 7 and B.MDCR_STATUS_CODE_07 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 8 and B.MDCR_STATUS_CODE_08 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 9 and B.MDCR_STATUS_CODE_09 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 10 and B.MDCR_STATUS_CODE_10 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 11 and B.MDCR_STATUS_CODE_11 in ("11", "21", "31")) or
    (a.adm_mo_6mo_b4 = 12 and B.MDCR_STATUS_CODE_12 in ("11", "21", "31")) 
    );
quit; *242;



data dialysis_carrier;
set Brown.carrier_09_19_merged;
if (HCPCS_CD > "A4652" and HCPCS_CD < "A4933") or (HCPCS_CD >= "90935" and HCPCS_CD <= "90999");
run; *486314;

PROC SQL;
CREATE TABLE Brown.valve_6moprior_carrier as
	SELECT main.*, sub.* 
	FROM temp.merge_denom_ESRD_no_prev_year as main
	INNER JOIN dialysis_carrier as sub
	on main.BENE_ID_denom=sub.BENE_ID and main.ADMSNDT - sub.LINE_1ST_EXPNS_DT <= 180 and main.ADMSNDT - sub.LINE_1ST_EXPNS_DT > 0;
QUIT; *N = 5577; 

data Brown.valve_6moprior_carrier;
set Brown.valve_6moprior_carrier;
EXPNS_MONTH = month(LINE_1ST_EXPNS_DT);
ADMSN_MONTH = month(ADMSNDT);
run;

proc sql;
create table count_n_of_dialysis as
select BENE_ID, ADMSNDT, 
count(distinct EXPNS_MONTH) as n_month

from Brown.valve_6moprior_carrier
group by BENE_ID, ADMSNDT;
quit; *N = 781;

data keepit;
set count_n_of_dialysis;
if n_month > 5;
run; *N = 253;

data unique_N_patients;
set keepit;
by BENE_ID;
if first.BENE_ID;
run; *N = 252;


*matching patients with 6 months prior regular dialysis carrier file
with patients who did not have previous year ESRD indicator.
This matching could include patients in 2015-2019, which may cause duplicates;
proc sql;
create table temp.ESRD_6mo_regular_0521 as 
select A.*
from  temp.merge_denom_ESRD_no_prev_year A 
inner join keepit B 
on A.BENE_ID_denom = B.BENE_ID 
and A.ADMSNDT = B.ADMSNDT;
quit; *256;

*Merging patients with previous year ESRD indicator with
the two datasets ;
data temp.AVR_all_0606;
set temp.merge_denom_ESRD_prev_year 
    temp.ESRD_no_prev_year_but_prev_6mo 
    temp.ESRD_6mo_regular_0521;
run; *N = 14943 + 242 + 256 = 15441 // 14931 + 242 + 256 = 15429;

proc sort data=temp.AVR_all_0606 out=temp.AVR_all_0606;
by BENE_ID ADMSNDT;
run;
data temp.AVR_all_0606;
set temp.AVR_all_0606;
by BENE_ID;
if first.BENE_ID;
run; *N = 15,093   15081;

***** RUN the ELIXHAUSER CODE; *****

*Tag Concimitant Procedure;
data temp.AVR_all_0606;
set temp.AVR_all_0606;

array prc[25] PRCDR_CD1 -- PRCDR_CD6 PRCDR_CD7 -- PRCDR_CD25; 

CABG = 0;

do i = 1 to 25;
    if RFRNC_YR > 2015 and substr(prc[i], 1, 4) in ("0210", "0211", "0212", "0213") then do;
        CABG = 1;
    end;
    if RFRNC_YR <= 2015 and substr(prc[i], 1, 3) in ("361", "362", "363") then do;
        CABG = 1;
    end;
end;

drop i;
run;

data AVR_all_0606;
set temp.AVR_all_0606;
keep BENE_ID ADMSNDT RFRNC_YR;
run;

proc sql;
  create table three_months_adm as
  select A.*, B.*
  from AVR_all_0606  A
  left join Brown.Medpar_PRCDR_DT B
  on A.BENE_ID = B.BENE_ID_medpar and (A.ADMSNDT - B.ADMSNDT_medpar <= 90 or B.ADMSNDT_medpar - A.ADMSNDT <= 90);
quit; *204023   203890;
data three_months_adm01;
set three_months_adm;

array prc[25] PRCDR_CD1 -- PRCDR_CD6 PRCDR_CD7 -- PRCDR_CD25; 

PCI = 0;
do i = 1 to 25;
    if RFRNC_YR > 2015 and substr(prc[i], 1, 4) in ("0270", "0271", "0272", "0273", 
    "02H0", "02H1", "02H2", "02H3") then do;
        PCI = 1;
    end;
    if RFRNC_YR <= 2015 and substr(prc[i], 1, 4) in ("0066", "1755", "3601", "3602", "3603", 
    "3605", "3606", "3607", "3609", "3633", "3634") then do;
        PCI = 1;
    end;
end;
drop i;
run;


proc sql;
create table three_months_adm02 as
select BENE_ID, 

SUM(CASE WHEN PCI > 0 THEN 1 ELSE 0 END) as PCI

from three_months_adm01
group by BENE_ID;
quit;

data three_months_adm03;
set three_months_adm02;
if PCI > 1 then PCI = 1 ;
run; 

proc sql;
  create table temp.AVR_all_0606 as
  select A.*, B.*
  from temp.AVR_all_0606  A
  inner join three_months_adm03 B
  on A.BENE_ID = B.BENE_ID;
quit; 


*Tag Valvular Disease;
data temp.AVR_all_0606;
set temp.AVR_all_0606;

array dx[25] DGNS_CD01 DGNS_CD10 DGNS_CD02 -- DGNS_CD09 DGNS_CD11 -- DGNS_CD24 DGNS_CD25; 

Aortic_Stenosis = 0;
do i = 1 to 25;
	if substr(dx[i], 1, 4) in ("3950", "3960", "3962", "7463", "I350", "I060", 
	"I062", "I080", "Q230") then do;
        Aortic_Stenosis = 1;
    end;
end;

Aortic_Insufficiency = 0;
do i = 1 to 25;
	if substr(dx[i], 1, 4) in ("3951", "3961", "3963", "7464", "I351", "I061", 
	"Q231") then do;
        Aortic_Insufficiency = 1;
    end;
end;

Aortic_Valve_Disorder = 0;
do i = 1 to 25;
	if substr(dx[i], 1, 4) in ("3952", "3968", "3969", "4241", "I358","I359", 
	"I068", "I069", "I082", "I083", "Q238", "Q239") then do;
        Aortic_Valve_Disorder = 1;
    end;
end;

drop i;
run; 


data AVR_all_0606_bene;
set temp.AVR_all_0606;
keep BENE_ID YEAR;
run;

proc sql;
  create table prev_yr_ESRD as
  select A.*, B.*
  from AVR_all_0606_bene  A
  inner join Denominator2009_2019_new B
  on A.BENE_ID = B.BENE_ID_denom and A.YEAR - B.RFRNC_YR > 0;
quit;

proc sql;
create table prev_yr_ESRD as
select BENE_ID, 

SUM(CASE WHEN ESRD_IND = "Y" THEN 1 ELSE 0 END) as ESRD_year

from prev_yr_ESRD
group by BENE_ID;
quit; *N = 14841  14829;

proc sql;
  create table temp.AVR_all_0606 as
  select A.*, B.*
  from temp.AVR_all_0606  A
  left join prev_yr_ESRD B
  on A.BENE_ID = B.BENE_ID;
quit;

data temp.AVR_all_0606;
set temp.AVR_all_0606;
ESRD_year = ESRD_year + 1;
if ESRD_year = . then ESRD_year = 1;
drop DEATH_DT;
run;

proc freq data= deathinfo;
table DEATH_DT;
run;

data death_info;
set Denominator2009_2019_new;
keep BENE_ID_denom DEATH_DT RFRNC_YR;
run;

proc sql;
  create table deathinfo as
  select A.*, B.*
  from AVR_all_0606_bene  A
  inner join death_info B
  on A.BENE_ID = B.BENE_ID_denom;
quit;

proc sort data=deathinfo out=deathinfo;
by BENE_ID RFRNC_YR;
run;
data deathinfo;
set deathinfo;
by BENE_ID;
if last.BENE_ID;
run; *N = 15,093  15081;
data deathinfo;
set deathinfo;
drop YEAR RFRNC_YR;
run;

proc sql;
  create table temp.AVR_all_0606 as
  select A.*, B.*
  from temp.AVR_all_0606  A
  inner join deathinfo B
  on A.BENE_ID = B.BENE_ID_denom;
quit;

data temp.AVR_all_0606;
set temp.AVR_all_0606;
valve_type = 0;
if Mechanical_AVR = 1 then valve_type = 1;
if Bioprosthetic_AVR = 1 then valve_type = 2;
if TAVR = 1 then valve_type = 3;
run;

proc freq data= temp.AVR_all_0606;
table valve_type*PCI;
run;

data temp.AVR_all_0606;
set temp.AVR_all_0606;
age = yrdif(BENE_DOB, ADMSNDT);
run;

PROC EXPORT DATA=temp.AVR_all_0606
OUTFILE="/project/Brown_Cardiac_Surgery/Data/AVR_all_0606.dta"			
DBMS=dta REPLACE;
RUN;

*For PSM;
PROC EXPORT DATA=temp.AVR_all_0606
OUTFILE="/project/Brown_Cardiac_Surgery/Data/AVR_all_0606.csv"			
DBMS=csv REPLACE;
RUN;


data temp.AVR_all_0813;
set temp.AVR_all_0606;
age = yrdif(BENE_DOB, ADMSNDT);
run;


/* Create indicators for IMMEDIATE secondary outcomes: */
data temp.AVR_all_0606;
set temp.AVR_all_0606;
/* data TAVR_matched_0626; */
/* set TAVR_matched_0626; */

array dx[25] DGNS_CD01 DGNS_CD10 DGNS_CD02-- DGNS_CD09 DGNS_CD11 -- DGNS_CD24 DGNS_CD25; 
array pcd[25] PRCDR_CD1 -- PRCDR_CD6 PRCDR_CD7 -- PRCDR_CD25; 

Cerebral_Hemorrhage = 0;
do i = 1 to 25;
    if substr(dx[i], 1, 3) in ("430", "431", "432", "I60", "I61", "I62") then do;
        Cerebral_Hemorrhage = 1;
    end;
end;

Ischemic_Stroke = 0;
do i = 1 to 25;
    if substr(dx[i], 1, 3) in ("I63", "I64", "I65", "I66") then do;
    	Ischemic_Stroke = 1;
    end;
    if substr(dx[i], 1, 4) in ("I679") then do;
    	Ischemic_Stroke = 1;
    end;
    if substr(dx[i], 1, 5) in ("I6781", "I6782", "I6789") then do;
    	Ischemic_Stroke = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 3) in ("433", "434", "436") then do;
    	Ischemic_Stroke = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 4) in ("4371", "4378", "4379") then do;
    	Ischemic_Stroke = 1;
    end;
end;

Cardiac_Arrest = 0;
do i = 1 to 25;
    if YEAR <= 2015 and substr(dx[i], 1, 4) = "4275" then do;
        Cardiac_Arrest = 1;
    end;
    if substr(dx[i], 1, 4) in ("I469") then do;
        Cardiac_Arrest = 1;
    end;
end;

Complete_Heart_Block = 0;
do i = 1 to 25;
    if substr(dx[i], 1, 4) in ("4260", "I440","I442") then do;
        Complete_Heart_Block = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 5) in ("42611") then do;
        Complete_Heart_Block = 1;
    end;
end;

GI_Hemorrhage = 0;
do i = 1 to 25;
    if dx[i] in ("4552", "4555", "4558", "4560", "45620", "5307", "53082", 
    "5310", "5311", "5312", "5313", "5314", "5315", "5316", "5320", "5321", 
    "5322", "5323", "5324", "5325", "5326", "5330", "5331", "5332", "5333", 
    "5334", "5335", "5336", "5340", "5341", "5342", "5343", "5344", "5345", 
    "5346", "53501", "53502", "53503", "53504", "53505", "53506", "53507", 
    "53508", "53509", "53510", "53511", "53512", "53513", "53514", "53515", 
    "53516", "53517", "53518", "53519", "53520", "53521", "53522", "53523", 
    "53524", "53525", "53526", "53527", "53528", "53529", "53530", "53531", 
    "53532", "53533", "53534", "53535", "53536", "53537", "53538", "53539", 
    "53540", "53541", "53542", "53543", "53544", "53545", "53546", "53547", 
    "53548", "53549", "53550", "53551", "53552", "53553", "53554", "53555", 
    "53556", "53557", "53558", "53559", "53560", "53561", "56202", "56203", 
    "56212", "56213", "5693", "56985", "5780", "5781", "5789", "53783", "56881",
    "I8501", "I8511", "K644", "K648", "K226", "K228", "K250", "K251", "K252", 
    "K253", "K254", "K255", "K256", "K260", "K261", "K262", "K263", "K264", "K265",
    "K266", "K270", "K271", "K272", "K273", "K274", "K275", "K276", "K280", "K281", 
    "K282", "K283", "K284", "K285", "K286", "K2901", "K2911", "K2921", "K2931", 
    "K2941", "K2951", "K2961", "K2971", "K2981", "K2991", "K5701", "K5711", 
    "K5713", "K5721", "K5731", "K5733", "K5741", "K5751", "K5753", "K5781", 
    "K5791", "K5793", "K625", "K5521", "K920", "K921", "K922", "K31811", "K661") then do;
        GI_Hemorrhage = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 4) in ("4552", "4555", "4558", "4560", "5307", 
    "5310", "5311", "5312", "5313", "5314", "5315", "5316", "5320", "5321", 
    "5322", "5323", "5324", "5325", "5326", "5330", "5331", "5332", "5333", 
    "5334", "5335", "5336", "5340", "5341", "5342", "5343", "5344", "5345", 
    "5346", "5693", "5780", "5781", "5789") then do;
        GI_Hemorrhage = 1;
    end;
    if substr(dx[i], 1, 4) in ("K644", "K648", "K226", "K228", "K250", "K251", "K252", 
    "K253", "K254", "K255", "K256", "K260", "K261", "K262", "K263", "K264", "K265",
    "K266", "K270", "K271", "K272", "K273", "K274", "K275", "K276", "K280", "K281", 
    "K282", "K283", "K284", "K285", "K286", "K625", "K920", "K921", "K922", "K661") then do;
        GI_Hemorrhage = 1;
    end;
end;

Other_Bleeding = 0;
do i = 1 to 25;
    if dx[i] in ("2851", "28659", "42989", "4230", "459", "59970", "59971", 
    "59972", "71911", "7847", "7848", "7863", "852", "853", "9901", "9904", 
    "99702", "9981", "9998", "D62", "D68311", "D68312", "D68318", "I312", "I513",
    "I9741", "I9742", "I9761", "K920", "M25019", "R042", "R040", "R041", "R042", 
    "R0481", "R0489", "R049", "R310", "R311", "R312", "R319", "R58", "S064X3A", 
    "S064X7A", "S065X1A", "S065X5A", "S065X9A", "S066X3A", "S066X7A", "S064X0A", 
    "S064X1A", "S064X4A", "S064X5A", "S064X8A", "S064X9A", "S065X2A", "S065X3A", 
    "S065X6A", "S065X7A", "S066X0A", "S066X1A", "S066X4A", "S066X5A", "S066X8A", 
    "S066X9A", "S064X2A", "S064X6A", "S065X0A", "S065X4A", "S065X8A", "S066X2A", 
    "S066X6") then do;
        Other_Bleeding = 1;
    end;
    if substr(dx[i], 1, 5) in ("28659", "42989", "59970", "59971", "59972", "71911",
    "59972", "71911", "I9741", "I9742", "I9761", "R0481", "R0489") then do;
        Other_Bleeding = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 4) in ("2851", "4230", "7847", "7848", "7863", "9901", "9904",
    "9981", "9998") then do;
        Other_Bleeding = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 3) in ("459", "852", "853") then do;
        Other_Bleeding = 1;
    end;
    if substr(dx[i], 1, 4) in ("I312", "I513", "K920", "R042", "R040", "R041", "R042",
    "R049", "R310", "R311", "R312", "R319") then do;
        Other_Bleeding = 1;
    end;
    if substr(dx[i], 1, 3) in ("D62", "R58") then do;
        Other_Bleeding = 1;
    end;
end;

RBC_Transfusion = 0;
do i = 1 to 25;
    if pcd[i] in ("30233N1","30243N1","30253N1","30233H0","30243H0","30253H0") then do;
        RBC_Transfusion = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 4) in ("9900", "9901","9902","9903","9904") then do;
        RBC_Transfusion = 1;
    end;
end;

Permanent_Pacemaker = 0;
do i = 1 to 25;
    if dx[i] in ("Z45010", "Z45018") then do;
        Permanent_Pacemaker = 1;
    end;
    if substr(dx[i], 1, 4) = "Z950" then do;
    	Permanent_Pacemaker = 1;
    end;
    if YEAR <= 2015 and substr(dx[i], 1, 5) in ("V4501", "V5331") then do;
    	Permanent_Pacemaker = 1;
    end;
    if pcd[i] in ("0JH60PZ", "0JH63PZ", "0JH80PZ", "0JH83PZ", "0JH604Z", "0JH634Z", "0JH804Z", "0JH834Z", 
    "0JH605Z", "0JH635Z", "0JH805Z", "0JH835Z", "0JH606Z", "0JH636Z", "0JH806Z", 
    "0JH836Z", "0JH607Z", "0JH637Z", "0JH807Z", "0JH837Z") then do;
        Permanent_Pacemaker = 1;
    end;
    if YEAR <= 2015 and substr(pcd[i], 1, 4) in ("3780", "3781", "3782", "3783", "0050", "0053") then do;
    	Permanent_Pacemaker = 1;
    end;
end;

New_Afib = 0;
do i = 1 to 25;
    if YEAR <= 2015 and substr(dx[i], 1, 5) = "42731" then do;
        New_Afib = 1;
    end;
    if substr(dx[i], 1, 4) in ("I480", "I481", "I482", "I489") then do;
    	New_Afib = 1;
    end;
end;

drop i;
run; 


PROC EXPORT DATA=temp.AVR_all_0813
OUTFILE="/project/Brown_Cardiac_Surgery/Data/AVR_all_0813.dta"			
DBMS=dta REPLACE;
RUN;

/* PROC EXPORT DATA=TAVR_matched_0626 */
/* OUTFILE="/project/Brown_Cardiac_Surgery/Data/TAVR_matched_0626.dta"			 */
/* DBMS=dta REPLACE; */
/* RUN; */





data AVR_all_0606;
set temp.AVR_all_0606;
drop DGNS_CD: PRCDR_CD: PRCDR_DT:;
run;

proc sql;
  create table temp.AVR_post_pcd_0607 as
  select A.*, B.*
  from Brown.Medpar_PRCDR_DT A
  right join AVR_all_0606 B
  on A.BENE_ID_medpar = B.BENE_ID and A.ADMSNDT_medpar - B.ADMSNDT > 0;
quit; *N = 83625  83570;


/* Mark Reoperation and Secondary Outcome */

data temp.AVR_post_pcd_0607_1;
set temp.AVR_post_pcd_0607;

array dgn[25] DGNS_CD01 DGNS_CD10 DGNS_CD02-- DGNS_CD09 DGNS_CD11 -- DGNS_CD24 DGNS_CD25; 
array prc[25] PRCDR_CD1 -- PRCDR_CD6 PRCDR_CD7 -- PRCDR_CD25; 
array date[25] PRCDR_DT1 -- PRCDR_DT6 PRCDR_DT7 -- PRCDR_DT25; 

Reoperation = 0;
Reoperation_date = 0;
Readmit_CHF = 0;
Readmit_CHF_date = 0;
Readmit_endocarditis = 0;
Readmit_endocarditis_date = 0;
Readmit_Cerebral_Hemo = 0;
Readmit_Cerebral_Hemo_date = 0;
Readmit_GI_bleed = 0;
Readmit_GI_bleed_date = 0;
Readmit_other_bleed = 0;
Readmit_other_bleed_date = 0;
Readmit_Hemorrhage = 0;
Readmit_Hemorrhage_date = 0;
Ischemic_Stroke = 0;
Ischemic_Stroke_date = 0;
Kidney_Transplant = 0;
Kidney_Transplant_date = 0;

do i = 1 to 25;

	if substr(prc[i], 1, 4) in ("5569", "0TY0", "0TY1") then do;
        Kidney_Transplant = 1;
        Kidney_Transplant_date = date[i];
    end;
    if substr(prc[i], 1, 3) in ("556") then do;
        Kidney_Transplant = 1;
        Kidney_Transplant_date = date[i];
    end;
    
    if prc[i] in ("3522", "3521", "3505", "3506", "3804", "3814", "3834", 
    "3844", "3845", "3864", "3971", "3973", "3978", "02RF0JZ", "02RF07Z", 
    "02RF08Z", "02RF0KZ", "02RF3", "02RF4", "02RX", "02RW", "02QX", "02QR", 
    "02VX", "02VW", "02HX", "02HW", "04R0", "04Q0", "04V0", "04H0") then do;
        Reoperation = 1; 
        Reoperation_date = date[i];
    end;
    if YEAR <= 2015 and substr(prc[i], 1, 4) in ("3522", "3521", "3505", 
    "3506", "3804", "3814", "3834", "3844", "3845", "3864", "3971", "3973", 
    "3978") then do;
        Reoperation = 1;
        Reoperation_date = date[i];
    end;
    if YEAR > 2015 and substr(prc[i], 1, 4) in ("02RX", "02RW", "02QX", 
    "02QR", "02VX", "02VW", "02HX", "02HW", "04R0", "04Q0", "04V0", "04H0") then do;
        Reoperation = 1;
        Reoperation_date = date[i];
    end;
    if substr(prc[i], 1, 5) in ("02RF3", "02RF4") then do;
        Reoperation = 1;
        Reoperation_date = date[i];
    end;
    
    if dgn[i] in ("421", "4210", "4219", "4211", "4249", "42499", "42490", "42491",
    "11281", "03642", "09884", "11404", "11515", "11594", "I33", "I330", "I339", 
    "A3951", "B376") then do;
        Readmit_endocarditis = 1;
		Readmit_endocarditis_date = ADMSNDT_medpar;
    end;
    if YEAR <= 2015 and substr(dgn[i], 1, 4) in ("4210", "4219", "4211", "4249") then do;
    	Readmit_endocarditis = 1;
		Readmit_endocarditis_date = ADMSNDT_medpar;
    end;
    if YEAR > 2015 and substr(dgn[i], 1, 4) in ("I330", "I339", "A3951", "B376") then do;
    	Readmit_endocarditis = 1;
		Readmit_endocarditis_date = ADMSNDT_medpar;
    end;
    if YEAR <= 2015 and substr(dgn[i], 1, 3) in ("421") then do;
    	Readmit_endocarditis = 1;
		Readmit_endocarditis_date = ADMSNDT_medpar;
    end;
    if YEAR > 2015 and substr(dgn[i], 1, 3) in ("I38", "I39", "I33") then do;
    	Readmit_endocarditis = 1;
		Readmit_endocarditis_date = ADMSNDT_medpar;
    end;
    
    if YEAR <= 2015 and dgn[1] in ("39891", "428", "4280", "4281", "4282", "42820", 
    "42821", "42822", "42823", "4283", "42830", "42831", "42832", "42833", "4284", 
    "42840", "42841", "42842", "42843", "4289", "429", "4290", "4291", "4292", 
    "4293", "4294", "4295", "4296", "4297", "42971", "42979", "4298", "42981", 
    "42982", "42983", "42989", "4299") then do;
        Readmit_CHF = 1;
        Readmit_CHF_date = ADMSNDT_medpar;
    end;
    if YEAR >= 2015 and dgn[1] in ("39891", "428", "4280", "4281", "4282", "42820", 
    "42821", "42822", "42823", "4283", "42830", "42831", "42832", "42833", "4284", 
    "42840", "42841", "42842", "42843", "4289", "429", "4290", "4291", "4292", 
    "4293", "4294", "4295", "4296", "4297", "42971", "42979", "4298", "42981", 
    "42982", "42983", "42989", "4299") then do;
        Readmit_CHF = 1;
        Readmit_CHF_date = ADMSNDT_medpar;
    end;
    
/*     if dgn[i] in ("39891", "40201", "40211", "40291", "40401", "40403", "40411",  */
/*     "40413", "40491", "40493") then do; */
/*         Readmit_CHF = 1; */
/*         Readmit_CHF_date = ADMSNDT_medpar; */
/*     end; */
/*     if YEAR > 2015 and substr(dgn[i], 1, 3) in ("I43", "I50") then do; */
/*     	Readmit_CHF = 1; */
/*         Readmit_CHF_date = ADMSNDT_medpar; */
/*     end; */
/*     if YEAR <= 2015 and substr(dgn[i], 1, 4) in ("4254", "4255", "4256", "4257", "4258",  */
/*     "4259", "4280", "4281", "4282", "4283", "4284", "4285", "4286", "4287", "4288",  */
/*     "4289") then do; */
/*     	Readmit_CHF = 1; */
/*         Readmit_CHF_date = ADMSNDT_medpar; */
/*     end; */
/*     if YEAR > 2015 and substr(dgn[i], 1, 4) in ( "I099", "I110", "I130", "I132",  */
/*     "I255", "I420", "I425", "I426", "I427", "I428", "I429", "P290") then do; */
/*     	Readmit_CHF = 1; */
/*         Readmit_CHF_date = ADMSNDT_medpar; */
/*     end; */
   
   if YEAR <=2015 and substr(dgn[i], 1, 3) in ("430", "431", "432") then do;
	    Readmit_Cerebral_Hemo = 1;
		Readmit_Cerebral_Hemo_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
        Readmit_Hemorrhage_date = ADMSNDT_medpar;
   end;

   if substr(dgn[i], 1, 3) in ("I60", "I61", "I62") then do;
	    Readmit_Cerebral_Hemo = 1;
		Readmit_Cerebral_Hemo_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
        Readmit_Hemorrhage_date = ADMSNDT_medpar;
   end;

   if dgn[i] in ("4552", "4555", "4558", "4560", "45620", "5307", "53082", 
   "5310", "5311", "5312", "5313", "5314", "5315", "5316", "5320", "5321", 
	"5322", "5323", "5324", "5325", "5326", "5330", "5331", "5332", "5333", 
	"5334", "5335", "5336", "5340", "5341", "5342", "5343", "5344", "5345", 
	"5346", "53501", "53502", "53503", "53504", "53505", "53506", "53507", 
	"53508", "53509", "53510", "53511", "53512", "53513", "53514", "53515", 
	"53516", "53517", "53518", "53519", "53520", "53521", "53522", "53523", 
	"53524", "53525", "53526", "53527", "53528", "53529", "53530", "53531", 
	"53532", "53533", "53534", "53535", "53536", "53537", "53538", "53539", 
	"53540", "53541", "53542", "53543", "53544", "53545", "53546", "53547", 
	"53548", "53549", "53550", "53551", "53552", "53553", "53554", "53555", 
	"53556", "53557", "53558", "53559", "53560", "53561", "56202", "56203", 
	"56212", "56213", "5693", "56985", "5780", "5781", "5789", "53783", "56881", 
	"I8501", "I8511", "K644", "K648", "K226", "K228", "K250", "K251", "K252", 
	"K253", "K254", "K255", "K256", "K260", "K261", "K262", "K263", "K264", 
	"K265", "K266", "K270", "K271", "K272", "K273", "K274", "K275", "K276", 
	"K280", "K281", "K282", "K283", "K284", "K285", "K286", "K2901", "K2911", 
	"K2921", "K2931", "K2941", "K2951", "K2961", "K2971", "K2981", "K2991", 
	"K5701", "K5711", "K5713", "K5721", "K5731", "K5733", "K5741", "K5751", 
	"K5753", "K5781", "K5791", "K5793", "K625", "K5521", "K920", "K921", "K922", 
	"K31811", "K661") then do;
		Readmit_GI_bleed = 1;
		Readmit_GI_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if YEAR <=2015 and substr(dgn[i], 1, 4) in ("4552", "4555", "4558", "4560", 
	"5307", "5310", "5311", "5312", "5313", "5314", "5315", "5316", "5320", 
	"5321", "5322", "5323", "5324", "5325", "5326", "5330", "5331", "5332", 
	"5333", "5334", "5335", "5336", "5340", "5341", "5342", "5343", "5344", 
	"5345", "5346", "5693", "5780", "5781", "5789") then do;
		 Readmit_GI_bleed = 1;
		 Readmit_GI_bleed_date = ADMSNDT_medpar;
    	 Readmit_Hemorrhage = 1;
     	 Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if substr(dgn[i], 1, 4) in ("K644", "K648", "K226", "K228", "K250", "K251", 
	"K252", "K253", "K254", "K255", "K256", "K260", "K261", "K262", "K263", 
	"K264", "K265", "K266", "K270", "K271", "K272", "K273", "K274", "K275", 
	"K276", "K280", "K281", "K282", "K283", "K284", "K285", "K286", "K625", 
	"K920", "K921", "K922", "K661") then do;
		Readmit_GI_bleed = 1;
		Readmit_GI_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if dgn[i] in ("2851", "28659", "42989", "4230", "459", "59970", "59971", 
	"59972", "71911", "7847", "7848", "7863", "852", "853", "99702", "9981", 
	"9998", "D62", "D68311", "D68312", "D68318", "I312", "I513", "I9741", 
	"I9742", "I9761", "K920", "M25019", "R042", "R040", "R041", "R042", "R0481", 
	"R0489", "R049", "R310", "R311", "R312", "R319", "R58", "S064X3A", 
	"S064X7A", "S065X1A", "S065X5A", "S065X9A", "S066X3A", "S066X7A", "S064X0A", 
	"S064X1A", "S064X4A", "S064X5A", "S064X8A", "S064X9A", "S065X2A", "S065X3A", 
	"S065X6A", "S065X7A", "S066X0A", "S066X1A", "S066X4A", "S066X5A", "S066X8A", 
	"S066X9A", "S064X2A", "S064X6A", "S065X0A", "S065X4A", "S065X8A", "S066X2A", 
	"S066X6") then do;
		Readmit_other_bleed = 1;
		Readmit_other_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if substr(dgn[i], 1, 5) in ("28659", "42989", "59970", "59971", "59972", 
	"71911", "59972", "71911", "I9741", "I9742", "I9761", "R0481", "R0489") then do;
		Readmit_other_bleed = 1;
		Readmit_other_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if YEAR <=2015 and substr(dgn[i], 1, 4) in ("2851", "4230", "7847", "7848", 
	"7863", "9981", "9998") then do;
		Readmit_other_bleed = 1;
		Readmit_other_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if YEAR <=2015 and substr(dgn[i], 1, 3) in ("459", "852", "853") then do;
		Readmit_other_bleed = 1;
		Readmit_other_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if substr(dgn[i], 1, 4) in ("I312", "I513", "K920", "R042", "R040", "R041", 
	"R042", "R049", "R310", "R311", "R312", "R319") then do;
		Readmit_other_bleed = 1;
		Readmit_other_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;

	if substr(dgn[i], 1, 3) in ("D62", "R58") then do;
		Readmit_other_bleed = 1;
		Readmit_other_bleed_date = ADMSNDT_medpar;
		Readmit_Hemorrhage = 1;
    	Readmit_Hemorrhage_date = ADMSNDT_medpar;
	end;
    
    if dgn[i] in ( "4371", "4378", "4379", "I6781", "I6782", "I6789", "I679") then do;
        Ischemic_Stroke = 1;
        Ischemic_Stroke_date = ADMSNDT_medpar;
    end;
    if substr(dgn[i], 1, 3) in ("433", "434", "436","I63", "I64", "I65", "I66") then do;
    	Ischemic_Stroke = 1;
        Ischemic_Stroke_date = ADMSNDT_medpar;
    end;
end;

drop i;
run;

proc sort data=temp.AVR_post_pcd_0607_1 out=temp.AVR_post_pcd_0607_1;
by BENE_ID ADMSNDT;
run;

*Calculate secondary outcome time after surgery;
data AVR_post_pcd_0607_1;
set temp.AVR_post_pcd_0607_1;
death_time = DEATH_DT - Procedure_date;
Reoperation_time = Reoperation_date - Procedure_date;
Readmit_Cerebral_Hemo_readm_time = Readmit_Cerebral_Hemo_date - Procedure_date;
Readmit_GI_bleed_time = Readmit_GI_bleed_date - Procedure_date;
Readmit_other_bleed_time = Readmit_other_bleed_date - Procedure_date;
Readmit_Hemorrhage_readm_time = Readmit_Hemorrhage_date - Procedure_date;
Ischemic_Stroke_readm_time = Ischemic_Stroke_date - Procedure_date;
Readmit_CHF_readm_time = Readmit_CHF_date - Procedure_date;
Readmit_endocarditis_readm_time = Readmit_endocarditis_date - Procedure_date;
Kidney_Transplant_readm_time = Kidney_Transplant_date - Procedure_date;
run;

/* proc freq data= temp.AVR_ALL_0606; */
/* table DEATH_DT; */
/* run; */

/* proc sql; */
/* SELECT * FROM AVR_post_pcd_0607_1 WHERE BENE_ID = "llllll00AlljX9Q"; */
/* quit; */



/* *************************************************************** */
/* ************ SECONDARY OUTCOME TABLE (if needed) 0615********** */
/* *************************************************************** */
data AVR_post_pcd_0607_1;
set AVR_post_pcd_0607_1;
death_30d = 0;
if (death_time < 31 and death_time > 0) then death_30d = 1;
Reop_30d = 0;
Reop_1yr = 0;
Reop_3yr = 0;
Reop_5yr = 0;
if (Reoperation_time < 31 and Reoperation_time > 0) then Reop_30d = 1;
if (Reoperation_time < 366 and Reoperation_time > 0) then Reop_1yr = 1;
if (Reoperation_time < 1100 and Reoperation_time > 0) then Reop_3yr = 1;
if (Reoperation_time < 1830 and Reoperation_time > 0) then Reop_5yr = 1;
Readmit_Cerebral_Hemo_30d = 0;
Readmit_Cerebral_Hemo_1yr = 0;
Readmit_Cerebral_Hemo_3yr = 0;
Readmit_Cerebral_Hemo_5yr = 0;
if (Readmit_Cerebral_Hemo_readm_time < 31 and Readmit_Cerebral_Hemo_readm_time > 0) then Readmit_Cerebral_Hemo_30d = 1;
if (Readmit_Cerebral_Hemo_readm_time < 366 and Readmit_Cerebral_Hemo_readm_time > 0) then Readmit_Cerebral_Hemo_1yr = 1;
if (Readmit_Cerebral_Hemo_readm_time < 1100 and Readmit_Cerebral_Hemo_readm_time > 0) then Readmit_Cerebral_Hemo_3yr = 1;
if (Readmit_Cerebral_Hemo_readm_time < 1830 and Readmit_Cerebral_Hemo_readm_time > 0) then Readmit_Cerebral_Hemo_5yr = 1;
Readmit_GI_bleed_30d = 0;
Readmit_GI_bleed_1yr = 0;
Readmit_GI_bleed_3yr = 0;
Readmit_GI_bleed_5yr = 0;
if (Readmit_GI_bleed_time < 31 and Readmit_GI_bleed_time > 0) then Readmit_GI_bleed_30d = 1;
if (Readmit_GI_bleed_time < 366 and Readmit_GI_bleed_time > 0) then Readmit_GI_bleed_1yr = 1;
if (Readmit_GI_bleed_time < 1100 and Readmit_GI_bleed_time > 0) then Readmit_GI_bleed_3yr = 1;
if (Readmit_GI_bleed_time < 1830 and Readmit_GI_bleed_time > 0) then Readmit_GI_bleed_5yr = 1;
Readmit_other_bleed_30d = 0;
Readmit_other_bleed_1yr = 0;
Readmit_other_bleed_3yr = 0;
Readmit_other_bleed_5yr = 0;
if (Readmit_other_bleed_time < 31 and Readmit_other_bleed_time > 0) then Readmit_other_bleed_30d = 1;
if (Readmit_other_bleed_time < 366 and Readmit_other_bleed_time > 0) then Readmit_other_bleed_1yr = 1;
if (Readmit_other_bleed_time < 1100 and Readmit_other_bleed_time > 0) then Readmit_other_bleed_3yr = 1;
if (Readmit_other_bleed_time < 1830 and Readmit_other_bleed_time > 0) then Readmit_other_bleed_5yr = 1;
Readmit_Hemorrhage_30d = 0;
Readmit_Hemorrhage_1yr = 0;
Readmit_Hemorrhage_3yr = 0;
Readmit_Hemorrhage_5yr = 0;
if (Readmit_Hemorrhage_readm_time < 31 and Readmit_Hemorrhage_readm_time > 0) then Readmit_Hemorrhage_30d = 1;
if (Readmit_Hemorrhage_readm_time < 366 and Readmit_Hemorrhage_readm_time > 0) then Readmit_Hemorrhage_1yr = 1;
if (Readmit_Hemorrhage_readm_time < 1100 and Readmit_Hemorrhage_readm_time > 0) then Readmit_Hemorrhage_3yr = 1;
if (Readmit_Hemorrhage_readm_time < 1830 and Readmit_Hemorrhage_readm_time > 0) then Readmit_Hemorrhage_5yr = 1;
Ischemic_Stroke_readm_30d = 0;
Ischemic_Stroke_readm_1yr = 0;
Ischemic_Stroke_readm_3yr = 0;
Ischemic_Stroke_readm_5yr = 0;
if (Ischemic_Stroke_readm_time < 31 and Ischemic_Stroke_readm_time > 0) then Ischemic_Stroke_readm_30d = 1;
if (Ischemic_Stroke_readm_time < 366 and Ischemic_Stroke_readm_time > 0) then Ischemic_Stroke_readm_1yr = 1;
if (Ischemic_Stroke_readm_time < 1100 and Ischemic_Stroke_readm_time > 0) then Ischemic_Stroke_readm_3yr = 1;
if (Ischemic_Stroke_readm_time < 1830 and Ischemic_Stroke_readm_time > 0) then Ischemic_Stroke_readm_5yr = 1;
Readmit_CHF_readm_30d = 0;
Readmit_CHF_readm_1yr = 0;
Readmit_CHF_readm_3yr = 0;
Readmit_CHF_readm_5yr = 0;
if (Readmit_CHF_readm_time < 31 and Readmit_CHF_readm_time > 0) then Readmit_CHF_readm_30d = 1;
if (Readmit_CHF_readm_time < 366 and Readmit_CHF_readm_time > 0) then Readmit_CHF_readm_1yr = 1;
if (Readmit_CHF_readm_time < 1100 and Readmit_CHF_readm_time > 0) then Readmit_CHF_readm_3yr = 1;
if (Readmit_CHF_readm_time < 1830 and Readmit_CHF_readm_time > 0) then Readmit_CHF_readm_5yr = 1;
Readmit_endocarditis_readm_30d = 0;
Readmit_endocarditis_readm_1yr = 0;
Readmit_endocarditis_readm_3yr = 0;
Readmit_endocarditis_readm_5yr = 0;
if (Readmit_endocarditis_readm_time < 31 and Readmit_endocarditis_readm_time > 0) then Readmit_endocarditis_readm_30d = 1;
if (Readmit_endocarditis_readm_time < 366 and Readmit_endocarditis_readm_time > 0) then Readmit_endocarditis_readm_1yr = 1;
if (Readmit_endocarditis_readm_time < 1100 and Readmit_endocarditis_readm_time > 0) then Readmit_endocarditis_readm_3yr = 1;
if (Readmit_endocarditis_readm_time < 1830 and Readmit_endocarditis_readm_time > 0) then Readmit_endocarditis_readm_5yr = 1;
Kidney_Transplant_readm_30d = 0;
Kidney_Transplant_readm_1yr = 0;
Kidney_Transplant_readm_3yr = 0;
Kidney_Transplant_readm_5yr = 0;
Kidney_Transplant_readm_10yr = 0;
if (Kidney_Transplant_readm_time < 31 and Kidney_Transplant_readm_time > 0) then Kidney_Transplant_readm_30d = 1;
if (Kidney_Transplant_readm_time < 366 and Kidney_Transplant_readm_time > 0) then Kidney_Transplant_readm_1yr = 1;
if (Kidney_Transplant_readm_time < 1100 and Kidney_Transplant_readm_time > 0) then Kidney_Transplant_readm_3yr = 1;
if (Kidney_Transplant_readm_time < 1830 and Kidney_Transplant_readm_time > 0) then Kidney_Transplant_readm_5yr = 1;
if Kidney_Transplant_readm_time > 0 then Kidney_Transplant_readm_10yr = 1;
run;


proc sql;
create table temp.AVR_outcome_indicators_0628 as
select BENE_ID, 

SUM(CASE WHEN death_30d > 0 THEN 1 ELSE 0 END) as death_30d,

SUM(CASE WHEN Reop_30d > 0 THEN 1 ELSE 0 END) as Reop_30d,
SUM(CASE WHEN Reop_1yr > 0 THEN 1 ELSE 0 END) as Reop_1yr,
SUM(CASE WHEN Reop_3yr > 0 THEN 1 ELSE 0 END) as Reop_3yr,
SUM(CASE WHEN Reop_5yr > 0 THEN 1 ELSE 0 END) as Reop_5yr,

SUM(CASE WHEN Readmit_Cerebral_Hemo_30d > 0 THEN 1 ELSE 0 END) as Readmit_Cerebral_Hemo_30d,
SUM(CASE WHEN Readmit_Cerebral_Hemo_1yr > 0 THEN 1 ELSE 0 END) as Readmit_Cerebral_Hemo_1yr,
SUM(CASE WHEN Readmit_Cerebral_Hemo_3yr > 0 THEN 1 ELSE 0 END) as Readmit_Cerebral_Hemo_3yr,
SUM(CASE WHEN Readmit_Cerebral_Hemo_5yr > 0 THEN 1 ELSE 0 END) as Readmit_Cerebral_Hemo_5yr,

SUM(CASE WHEN Readmit_GI_bleed_30d > 0 THEN 1 ELSE 0 END) as Readmit_GI_bleed_30d,
SUM(CASE WHEN Readmit_GI_bleed_1yr > 0 THEN 1 ELSE 0 END) as Readmit_GI_bleed_1yr,
SUM(CASE WHEN Readmit_GI_bleed_3yr > 0 THEN 1 ELSE 0 END) as Readmit_GI_bleed_3yr,
SUM(CASE WHEN Readmit_GI_bleed_5yr > 0 THEN 1 ELSE 0 END) as Readmit_GI_bleed_5yr,

SUM(CASE WHEN Readmit_other_bleed_30d > 0 THEN 1 ELSE 0 END) as Readmit_other_bleed_30d,
SUM(CASE WHEN Readmit_other_bleed_1yr > 0 THEN 1 ELSE 0 END) as Readmit_other_bleed_1yr,
SUM(CASE WHEN Readmit_other_bleed_3yr > 0 THEN 1 ELSE 0 END) as Readmit_other_bleed_3yr,
SUM(CASE WHEN Readmit_other_bleed_5yr > 0 THEN 1 ELSE 0 END) as Readmit_other_bleed_5yr,

SUM(CASE WHEN Readmit_Hemorrhage_30d > 0 THEN 1 ELSE 0 END) as Readmit_Hemorrhage_30d,
SUM(CASE WHEN Readmit_Hemorrhage_1yr > 0 THEN 1 ELSE 0 END) as Readmit_Hemorrhage_1yr,
SUM(CASE WHEN Readmit_Hemorrhage_3yr > 0  THEN 1 ELSE 0 END) as Readmit_Hemorrhage_3yr,
SUM(CASE WHEN Readmit_Hemorrhage_5yr > 0 THEN 1 ELSE 0 END) as Readmit_Hemorrhage_5yr,

SUM(CASE WHEN Ischemic_Stroke_readm_30d > 0 THEN 1 ELSE 0 END) as Ischemic_Stroke_readm_30d,
SUM(CASE WHEN Ischemic_Stroke_readm_1yr > 0 THEN 1 ELSE 0 END) as Ischemic_Stroke_readm_1yr,
SUM(CASE WHEN Ischemic_Stroke_readm_3yr > 0 THEN 1 ELSE 0 END) as Ischemic_Stroke_readm_3yr,
SUM(CASE WHEN Ischemic_Stroke_readm_5yr > 0 THEN 1 ELSE 0 END) as Ischemic_Stroke_readm_5yr,

SUM(CASE WHEN Readmit_CHF_readm_30d > 0 THEN 1 ELSE 0 END) as Readmit_CHF_readm_30d,
SUM(CASE WHEN Readmit_CHF_readm_1yr > 0 THEN 1 ELSE 0 END) as Readmit_CHF_readm_1yr,
SUM(CASE WHEN Readmit_CHF_readm_3yr > 0 THEN 1 ELSE 0 END) as Readmit_CHF_readm_3yr,
SUM(CASE WHEN Readmit_CHF_readm_5yr > 0 THEN 1 ELSE 0 END) as Readmit_CHF_readm_5yr,

SUM(CASE WHEN Readmit_endocarditis_readm_30d > 0 THEN 1 ELSE 0 END) as Readmit_endocarditis_readm_30d,
SUM(CASE WHEN Readmit_endocarditis_readm_1yr > 0 THEN 1 ELSE 0 END) as Readmit_endocarditis_readm_1yr,
SUM(CASE WHEN Readmit_endocarditis_readm_3yr > 0 THEN 1 ELSE 0 END) as Readmit_endocarditis_readm_3yr,
SUM(CASE WHEN Readmit_endocarditis_readm_5yr > 0 THEN 1 ELSE 0 END) as Readmit_endocarditis_readm_5yr,

SUM(CASE WHEN Kidney_Transplant_readm_30d > 0 THEN 1 ELSE 0 END) as Kidney_Transplant_readm_30d,
SUM(CASE WHEN Kidney_Transplant_readm_1yr > 0 THEN 1 ELSE 0 END) as Kidney_Transplant_readm_1yr,
SUM(CASE WHEN Kidney_Transplant_readm_3yr > 0 THEN 1 ELSE 0 END) as Kidney_Transplant_readm_3yr,
SUM(CASE WHEN Kidney_Transplant_readm_5yr > 0 THEN 1 ELSE 0 END) as Kidney_Transplant_readm_5yr,
SUM(CASE WHEN Kidney_Transplant_readm_10yr > 0 THEN 1 ELSE 0 END) as Kidney_Transplant_readm_10yr

from AVR_post_pcd_0607_1
group by BENE_ID;
quit;

proc freq data = temp.AVR_outcome_indicators_0628;
table death_30d Readmit_Hemorrhage_3yr Readmit_Cerebral_Hemo_3yr Readmit_other_bleed_3yr Readmit_GI_bleed_3yr Ischemic_Stroke_readm_3yr Readmit_CHF_readm_3yr Readmit_endocarditis_readm_3yr Kidney_Transplant_readm_5yr Kidney_Transplant_readm_10yr;
run;

proc sql;
  create table Brown.TAVR_table2_outcome_0628 as
  select A.*, B.*
  from TAVR_matched_0626  A
  left join temp.AVR_outcome_indicators_0628 B
  on A.BENE_ID_denom = B.BENE_ID;
quit;

/* proc freq data = Brown.SAVR_table2_outcome_0628; */
/* table Readmit_other_bleed_3yr*valve_type; */
/* run; */

PROC EXPORT DATA=Brown.TAVR_table2_outcome_0628
OUTFILE="/project/Brown_Cardiac_Surgery/Data/TAVR_table2_outcome_0628.dta"			
DBMS=dta REPLACE;
RUN;

proc sql;
  create table AVR_all_0606 as
  select A.*, B.*
  from temp.AVR_all_0606  A
  left join temp.AVR_outcome_indicators_0628 B
  on A.BENE_ID = B.BENE_ID;
quit;

PROC EXPORT DATA=AVR_all_0606
OUTFILE="/project/Brown_Cardiac_Surgery/Data/AVR_all_0606.dta"			
DBMS=dta REPLACE;
RUN;

*Matched cohort for table 2;
*SAVR;
proc sql;
  create table SAVR_all_matched_0621 as
  select A.*, B.*
  from temp.AVR_all_0813  A
  inner join SAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit;

PROC EXPORT DATA=SAVR_all_matched_0621
OUTFILE="/project/Brown_Cardiac_Surgery/Data/SAVR_all_matched_0812.dta"			
DBMS=dta REPLACE;
RUN;

*TAVR;
proc sql;
  create table TAVR_all_matched_0621 as
  select A.*, B.*
  from temp.AVR_all_0813  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit;

PROC EXPORT DATA=TAVR_all_matched_0621
OUTFILE="/project/Brown_Cardiac_Surgery/Data/TAVR_all_matched_0812.dta"			
DBMS=dta REPLACE;
RUN;

/* *************************************************************** */
/*  Generate Base data for KM analysis - BENE_ID & Procedure_date  */
/* *************************************************************** */
proc sort data=AVR_post_pcd_0607_1;
  by BENE_ID ADMSNDT_medpar;
run; *83625  83570;

data base;
set AVR_post_pcd_0607_1;
if (ADMSNDT = ADMSNDT_medpar & Procedure_date = 0) then delete;
if Procedure_date = . then Procedure_date = ADMSNDT;
run; *83625  83570;

proc sort data=base;
  by BENE_ID ADMSNDT_medpar;
run;

data keepfirst;
  set base;
  by BENE_ID;
  if first.BENE_ID;
run; *N = 15093  15081;

proc freq data = keepfirst;
table Procedure_date;
run; *Make sure there's no missing and no "0" in Procedure_date;

data Brown.base_AVR_KM_data_0611;
set keepfirst (keep = BENE_ID Procedure_date valve_type);
run; *N = 15093  15081;

proc contents data=Brown.base_AVR_KM_data_0611;run; 

/* *********************************** */
/* Generate Death date time stamp data */
/* *********************************** */
proc sort data=AVR_post_pcd_0607_1;
  by BENE_ID ADMSNDT_medpar;
run;

data Brown.death_info_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID DEATH_DT);
if DEATH_DT > 0;
run; 

data Brown.death_info_AVR_0611;
set Brown.death_info_AVR_0611;
Event_date = DEATH_DT;
Event_name = "1";
drop DEATH_DT;
run; 

data Brown.death_info_AVR_0611;
  set Brown.death_info_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run; *N = 9517  9507 patients died by the end of data (2019);

proc contents data=Brown.death_info_AVR_0611;run; 

/* ****************************************** */
/* Generate Kidney transplant time stamp data */
/* ****************************************** */
proc sort data=AVR_post_pcd_0607_1;
  by BENE_ID ADMSNDT_medpar;
run;

data Brown.kidney_info_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Kidney_Transplant_date);
if Kidney_Transplant_date > 0;
run; 

data Brown.kidney_info_AVR_0611;
set Brown.kidney_info_AVR_0611;
Event_date = Kidney_Transplant_date;
Event_name = "2";
drop Kidney_Transplant_date;
run; *N = 563;

data Brown.kidney_info_AVR_0611;
  set Brown.kidney_info_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run;  *N = 561, two patient got two times kidney tranplant, we are keeping the first date;

proc contents data=Brown.kidney_info_AVR_0611;run; 

/* ******************************************* */
/* Generate Secondary Outcomes time stamp data */
/* ******************************************* */

proc sort data=AVR_post_pcd_0607_1;
  by BENE_ID ADMSNDT_medpar;
run;

data Brown.reoperation_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Reoperation_date);
if Reoperation_date > 0;
Event_date = Reoperation_date;
Event_name = "3";
drop Reoperation_date;
run; *N = 441;

data Brown.reoperation_AVR_0611;
  set Brown.reoperation_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run;  *N = 417;


data Brown.reCHF_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Readmit_CHF_date);
if Readmit_CHF_date > 0;
Event_date = Readmit_CHF_date;
Event_name = "4";
drop Readmit_CHF_date;
run; *N = 2049;

data Brown.reCHF_AVR_0611;
  set Brown.reCHF_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run;  *N = 1211;


data Brown.reEndocarditis_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Readmit_endocarditis_date);
if Readmit_endocarditis_date > 0;
Event_date = Readmit_endocarditis_date;
Event_name = "5";
drop Readmit_endocarditis_date;
run; *N = 2015;

data Brown.reEndocarditis_AVR_0611;
  set Brown.reEndocarditis_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run;  *N = 1210;


data Brown.reCerebralHemo_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Readmit_Cerebral_Hemo_date);
if Readmit_Cerebral_Hemo_date > 0;
Event_date = Readmit_Cerebral_Hemo_date;
Event_name = "6";
drop Readmit_Cerebral_Hemo_date;
run; *N = 549;

data Brown.reCerebralHemo_AVR_0611;
  set Brown.reCerebralHemo_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run;  *N = 422;


data Brown.reGIbleed_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Readmit_GI_bleed_date);
if Readmit_GI_bleed_date > 0;
Event_date = Readmit_GI_bleed_date;
Event_name = "7";
drop Readmit_GI_bleed_date;
run; *N = 3910;

data Brown.reGIbleed_AVR_0611;
  set Brown.reGIbleed_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run; *N = 3910;


data Brown.reotherbleed_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Readmit_other_bleed_date);
if Readmit_other_bleed_date > 0;
Event_date = Readmit_other_bleed_date;
Event_name = "8";
drop Readmit_other_bleed_date;
run; *N = 10569;

data Brown.reotherbleed_AVR_0611;
  set Brown.reotherbleed_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run;  *N = 5517;


data Brown.Stroke_AVR_0611;
set AVR_post_pcd_0607_1 (keep=BENE_ID Ischemic_Stroke_date);
if Ischemic_Stroke_date > 0;
Event_date = Ischemic_Stroke_date;
Event_name = "9";
drop Ischemic_Stroke_date;
run; *N = 3010;

data Brown.Stroke_AVR_0611;
  set Brown.Stroke_AVR_0611;
  by BENE_ID;
  if first.BENE_ID;
run;  *N = 1942;

/* ********************************************************************** */
/* Merge Death, Kidney Transplant, and Secondary Outcomes with Base Data  */
/* ********************************************************************** */

proc import datafile="/project/Brown_Cardiac_Surgery/Data/SAVR_matched_0626.csv"
        out=SAVR_matched_0626
        dbms=csv
        replace;
*N = 4934;
data SAVR_matched_0626;
set SAVR_matched_0626;
keep BENE_ID_denom valve_type;
run;

proc import datafile="/project/Brown_Cardiac_Surgery/Data/TAVR_matched_0812.csv"
        out=TAVR_matched_0626
        dbms=csv
        replace;
*N = 6412;
data TAVR_matched_0626;
set TAVR_matched_0626;
keep BENE_ID_denom valve_type;
run;

data all_event;
set Brown.death_info_AVR_0611 Brown.kidney_info_AVR_0611 Brown.reoperation_AVR_0611 Brown.reCHF_AVR_0611 
Brown.reEndocarditis_AVR_0611 Brown.reHemorrhage_AVR_0611 Brown.Stroke_AVR_0611; 
run; *N = 30615   30596;



/* *Merge death - KM; */
/* proc sql; */
/*   create table primary_outcome as */
/*   select B.*, A.* */
/*   from Brown.death_info_AVR_0611  A */
/*   right join Brown.base_AVR_KM_data_0611 B */
/*   on A.BENE_ID = B.BENE_ID; */
/* quit; */
/*  */
/* proc sql; */
/* create table no_transplant as  */
/* ((select BENE_ID from primary_outcome)  */
/* except (select BENE_ID from Brown.kidney_info_AVR_0611)); */
/* quit; *14520; */
/*  */
/* proc sql; */
/*   create table death_outcome as */
/*   select B.*, A.* */
/*   from primary_outcome  A */
/*   inner join no_transplant B */
/*   on A.BENE_ID = B.BENE_ID; */
/* quit; */
/*  */
/* PROC EXPORT DATA=death_outcome */
/* OUTFILE="/project/Brown_Cardiac_Surgery/Data/AVR_KM_death_0611.dta"			 */
/* DBMS=dta REPLACE; */
/* RUN; */
* 14520;
/* proc sql; */
/*   create table death_outcome_TAVR_matched as */
/*   select B.*, A.* */
/*   from death_outcome  A */
/*   inner join TAVR_matched_0626 B */
/*   on A.BENE_ID = B.BENE_ID_denom; */
/* quit; *6,234; */
/* PROC EXPORT DATA=death_outcome_TAVR_matched */
/* OUTFILE="/project/Brown_Cardiac_Surgery/Data/TAVR_KM_death_0812.dta"			 */
/* DBMS=dta REPLACE; */
/* RUN; */
*SAVR 4576, 4934-4576 = censored 358 kidney transplant patients;
*TAVR 5747, 5928-5747 = censored 181 kidney transplant patients;



proc sql;
  create table kidney as
  select B.*, A.*
  from Brown.kidney_info_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *561;

proc sql;
  create table primary_outcome as
  select B.*, A.*
  from Brown.death_info_AVR_0611  A
  right join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *15081;

proc sql;
  create table reoperation as
  select B.*, A.*
  from Brown.reoperation_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *417;

proc sql;
  create table reCHF as
  select B.*, A.*
  from Brown.reCHF_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *1211;

proc sql;
  create table reEndocarditis as
  select B.*, A.*
  from Brown.reEndocarditis_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *1210;

proc sql;
  create table reCerebralHemo as
  select B.*, A.*
  from Brown.reCerebralHemo_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *422;

proc sql;
  create table reGIbleed as
  select B.*, A.*
  from Brown.reGIbleed_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *3910;

proc sql;
  create table reotherbleed as
  select B.*, A.*
  from Brown.reotherbleed_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *5517;

proc sql;
  create table Stroke as
  select B.*, A.*
  from Brown.Stroke_AVR_0611  A
  inner join Brown.base_AVR_KM_data_0611 B
  on A.BENE_ID = B.BENE_ID;
quit; *1942;



PROC EXPORT DATA=death_matched_excl_kidney
OUTFILE="/project/Brown_Cardiac_Surgery/Data/SAVR_KM_death_0701.dta"			
DBMS=dta REPLACE;
RUN; 



proc sql;
  create table death_outcome_matched as
  select B.*, A.*
  from primary_outcome  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *4934 / 5928, including kidney tranplant patients;

proc sql;
  create table kidney_matched as
  select B.*, A.*
  from kidney  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *358  / 181;

proc sql;
  create table reop_outcome_matched as
  select B.*, A.*
  from reoperation  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *251  / 133;

proc sql;
  create table reCHF_matched as
  select B.*, A.*
  from reCHF  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *711  /  490;

proc sql;
  create table  reEndocarditis_matched as
  select B.*, A.*
  from reEndocarditis  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *565  /  434;

proc sql;
  create table reCerebralHemo_matched as
  select B.*, A.*
  from reCerebralHemo  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *199  /  154;

proc sql;
  create table reGIbleed_matched as
  select B.*, A.*
  from reGIbleed  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *1471  / 1516;

proc sql;
  create table reotherbleed_matched as
  select B.*, A.*
  from reotherbleed  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *2162  / 2173;

proc sql;
  create table Stroke_matched as
  select B.*, A.*
  from Stroke  A
  inner join TAVR_matched_0626 B
  on A.BENE_ID = B.BENE_ID_denom;
quit; *696  / 750; 



data bbb;
set death_outcome_matched kidney_matched reop_outcome_matched reCHF_matched reEndocarditis_matched reCerebralHemo_matched reGIbleed_matched reotherbleed_matched Stroke_matched ;
run; *11347 / 12643;

/* proc freq data= bbb; */
/* table valve_type; */
/* run; */

PROC EXPORT DATA=bbb
OUTFILE="/project/Brown_Cardiac_Surgery/Data/TAVR_CoxModel_matched_0807.dta"			
DBMS=dta REPLACE;
RUN;


