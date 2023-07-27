/*Derving DS DOMAIN*/


options validvarname = Upcase missing = '';

Data Demo1;
length studyid $11 Dm$2 usubjid $25 ;
Set Raw.Demowide (Where = (tpcode ne '') Drop = studyid);
STUDYID = Strip(STUDY);
DM = "DS";
USUBJID = catx('-', STUDY, STDYSITE, PATIENT);
 
Keep studyid dm usubjid ;
run;
 proc sort data = Demo1;
 by usubjid;
 run;


Data Eg;
 Length usubjid $25  Dsterm $200 dsdecod$200 dscat$100  dsstdtc $18;
set raw.eligibil (WHERE=(TPCODE NE '' and LBLSTYP='Consent' and Consdt ne .));
USUBJID = catx('-', STUDY, STDYSITE, PATIENT);
      DSTERM = 'INFORMED CONSENT OBTAINED';
	  DSDECOD = 'INFORMED CONSENT OBTAINED';
	  DSCAT = 'Protocol Milestone';
	   DSSTDTC = put(datepart(Consdt), is8601da.);
	 Keep  usubjid dsterm dsdecod dscat dsstdtc;
	 run;

proc sort data = Eg;
by Usubjid;
run;

Data rn;
 Length usubjid $25  Dsterm $200 dsdecod$200 dscat$100  dsstdtc $18;
set raw.Random;
USUBJID = catx('-', STUDY, STDYSITE, PATIENT);
 If RANDN NE '' AND  VISITDT ne . then 
DSTERM='RANDOMIZED' ;
DSDECOD = 'RANDOMIZED';
DSCAT = 'Protocol Milestone';
DSSTDTC = put(datepart(VISITDT), is8601da.);
 Keep  usubjid dsterm dsdecod dscat dsstdtc;
 RUN;


proc sort data = rn;
by Usubjid;
run;


Proc sort data = Raw.Conclus;
by patient;
run;

data Cn1;
 Length usubjid $25  Dsterm $200 dsdecod$200 dscat$100  dsstdtc $18;
   set Raw.Conclus (WHERE=(TPCODE NE ''));
USUBJID = catx('-', STUDY, STDYSITE, PATIENT);

if SFAILYN='No' AND RSNTRM='Subject Request' AND RSNTMX IN('Secondary to diarrhea.','Pt. felt toxicities were unacceptable.')
THEN DSTERM=upcase(strip(RSNTMX)); ELSE DSTERM=upcase(strip(RSNTRM));
if SFAILYN='Yes' then DSTERM=upcase('SCREEN FAILURE');

If RSNTRM IN('Adverse Event not related to test articl','Adverse Event related to test article')
then DSDECOD='ADVERSE EVENT';
Else If RSNTRM='Death' then DSDECOD='DEATH';
Else If RSNTRM='Disease Progression' then DSDECOD='PROGRESSIVE DISEASE';
Else if RSNTRM='Failed to Return' then DSDECOD='LOST-TO-FOLLOWUP';
Else if RSNTRM='Other: Investigator clinical judgement r' then DSDECOD='PHYSICIAN DECISION';
Else If RSNTRM='Study Completed' then DSDECOD= 'COMPLETED';
Else if RSNTRM='Subject Request' AND RSNTMX IN ('Patient withdrew consent.','Withdrawal of consent.','Patient decided not to continue this treatment because she believed it was not working..')
then DSDECOD='CONSENT WITHDRAWN';
Else If RSNTRM='Subject Request' then DSDECOD='SUBJECT REQUEST';
Else IF RSNTRM='Symptomatic Deterioration' then DSDECOD=UPCASE('Symptomatic Deterioration');
IF SFAILYN='Yes' then DSDECOD='SCREEN FAILURE';
DSCAT = 'DISPOSITION EVENT';
DSSCAT = upcase(strip(LBLSTYP));
DSSTDTC = put(datepart(TERMDT), is8601da.);
DSDTC = put(datepart(TERMDT), is8601da.);
KEEP   USUBJID DSTERM DSDECOD DSCAT DSSTDTC ;

run;



 
proc sort data = cn1;
by Usubjid;
run;





Data ds;
merge  demo1  (in=a) Eg  Rn Cn1;
by usubjid;
if a  ;
run;



proc sort data= ds;
by usubjid;
run;

Data d1;
Set Sdtm.DM;;
Keep Usubjid Rfstdtc Rfendtc;
Run;
proc sort data= d1;
by usubjid;
run;


data Dmds;
Merge ds (in = a) d1  ;
BY USUBJID;
IF A ;
keep Studyid DM Usubjid dsterm dsdecod dscat dsstdtc Rfstdtc Rfendtc;
RUN;



Data DY;
length USUBJID $25 DSSTDY $8 EPOCH $20;
Set Dmds;
IF RFSTDTC NE '' THEN RFSTDT=INPUT(RFSTDTC,YYMMDD10.);
IF RFENDTC NE '' THEN RFENDT=INPUT(RFENDTC,YYMMDD10.);
IF DSSTDTC NE '' THEN DSSTDT=INPUT(DSSTDTC,YYMMDD10.);
IF NMISS(DSSTDT,RFSTDT)=0 THEN DO;
IF DSSTDT<RFSTDT THEN DSSTDY=DSSTDT-RFSTDT;
ELSE IF DSSTDT>=RFSTDT THEN DSSTDY=(DSSTDT-RFSTDT)+1;
END;


IF DSSTDTC<RFSTDTC THEN EPOCH="SCREENING";
ELSE IF DSSTDTC>=RFSTDTC AND DSSTDTC<=RFENDTC THEN EPOCH='TREATMENT';
ELSE IF DSSTDTC>RFENDTC THEN EPOCH='FOLLOW-UP';

run;




PROC SORT DATA=DY (DROP=RFSTDT RFSTDTC RFENDT RFENDTC );
BY USUBJID;
RUN;

PROC SORT DATA=DY OUT=Ds4 NODUPKEY DUPOUT=DS5;
BY USUBJID DSTERM DSDECOD DSCAT ;
RUN;

DATA DS6;
SET Ds4;
BY USUBJID DSTERM;
IF FIRST.USUBJID THEN DSSEQ=1;
ELSE DSSEQ+1;
RUN;

DATA SDTM.DS1;
SET DS6;
ATTRIB
STUDYID LABEL='Study Identifier'
DM	LABEL='Domain'
USUBJID	LABEL='Unique Subject Identifier'
DSSEQ	LABEL='Sequence Number'
DSTERM	LABEL='Reported Term for the Disposition Event'
DSDECOD	LABEL='Standardized Disposition Term'
DSCAT	LABEL='Category for Disposition Event'
EPOCH	LABEL='Epoch'
DSSTDTC	LABEL='Start Date/Time of Disposition Event'
DSSTDY	LABEL='Study Day of Start of Disposition Event';
RUN;


