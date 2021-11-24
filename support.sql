/*
 * Various support queries
 */


(select programstageid from programstage where uid = 'edyRc6d5Bts') -- 26539 Laboratory, 1:TB Surveillance Program
(SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir') -- 31341 6: TB-Refill Event programme
/*
        transfer.eventdatavalues -> 'WTz4HSqoE5E' -- DSLT-12 : Follow up lab Results
        transfer.eventdatavalues -> 'KNRRxYxjtOz' -- DSLT-11 : Results others(specify)
        transfer.eventdatavalues -> 't1wRW4bpRrj' -- DSLT-01 : Type of Test
        transfer.eventdatavalues -> 'U4jSUZPF0HH' -- DS: Month of Treatment
*/

-- SELECT variant of STATUS UPDATE query:
SELECT * FROM programstageinstance psiupdate
	--set status = 'COMPLETED',
    --set TRANSFER MODE to AUTOMATICALLY 
    --eventdatavalues = jsonb_set(psiupdate.eventdatavalues, '{iup9aING8xC,value}', '"AUTOMATICALLY"')
    JOIN programstageinstance psifrom on psiupdate.programstageinstanceid = psifrom.programstageinstanceid
    JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7'
    JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ'
    -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA - District TB No
    /*
    join trackedentityattributevalue teav
    on teav.trackedentityattributeid = tea.trackedentityattributeid
    and teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}'
    */
    -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
    join trackedentityattributevalue teav2 -- ???
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psifrom.eventdatavalues#>>'{"XupJDPkqWoL","value"}'
    -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
    join trackedentityattributevalue teav3 -- ???
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psifrom.eventdatavalues#>>'{"bvuRnNr6INS","value"}'

    join trackedentityinstance tei on tei.trackedentityinstanceid = teav2.trackedentityinstanceid
    join programinstance pi on pi.trackedentityinstanceid = tei.trackedentityinstanceid and pi.deleted = false and pi.status = 'ACTIVE'

    where psifrom.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    and (psifrom.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
    and psifrom.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED'
    --and psiupdate.programstageinstanceid = psifrom.programstageinstanceid
	;

-- SELECT variant of Lab result transfer query:
WITH transfer AS (
    UPDATE programstageinstance psiupdate
    SET status = psiupdate.status
    FROM programstageinstance psifrom
    JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
    JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full name

    -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
    join trackedentityattributevalue teav2
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psifrom.eventdatavalues#>>'{"XupJDPkqWoL","value"}'

    -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
    join trackedentityattributevalue teav3
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psifrom.eventdatavalues#>>'{"bvuRnNr6INS","value"}'

    JOIN trackedentityinstance tei on tei.trackedentityinstanceid = teav2.trackedentityinstanceid
    JOIN programinstance pi on pi.trackedentityinstanceid = tei.trackedentityinstanceid and pi.deleted = false and pi.status = 'ACTIVE' -- ?? Do we really want to check whether pi.status = 'ACTIVE'?

    WHERE psifrom.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    AND (psifrom.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
    AND psifrom.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'AUTOMATICALLY'
    AND psifrom.status = 'ACTIVE'
    AND psifrom.eventdatavalues#>>'{"WTz4HSqoE5E","value"}' IS NOT NULL
    AND psiupdate.programstageinstanceid = psifrom.programstageinstanceid

    RETURNING 
    nextval('programstageinstance_sequence') as destpsiid, 
    (select programstageid from programstage where uid = 'edyRc6d5Bts') as destpsid, 
    psifrom.*, 
    pi.programinstanceid as destinationpi
)
SELECT * FROM transfer;


With transfer AS (
    SELECT programstageinstanceid, uid, programinstanceid, programstageid, storedby, organisationunitid, status, eventdatavalues,
        eventdatavalues
    FROM programstageinstance psi
    WHERE psi.programstageid =
    (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    AND programstageinstanceid = 87
)
SELECT * FROM transfer;


SELECT * FROM programstage WHERE programstageid IN (26539,26653);


-------------- TEST --------------

WITH source AS (
SELECT psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' full_name,
  psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}' unit_tb_no,
  psi.eventdatavalues#>>'{"JpvpfVIjK7x","value"}' transfer_to_orgunit
  FROM programstageinstance psi
  WHERE psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' = 'PERMANENT_TRANSFER'
  AND psi.status = 'COMPLETED')

SELECT pi.*, teav1.trackedentityinstanceid, teav1.trackedentityattributeid, teav1.value, teav2.trackedentityinstanceid ,teav2.trackedentityattributeid, teav2.value
  FROM programinstance pi
  JOIN trackedentityinstance tei ON pi.trackedentityinstanceid = tei.trackedentityinstanceid
  JOIN trackedentityattributevalue teav1 ON teav1.trackedentityinstanceid = tei.trackedentityinstanceid AND teav1.trackedentityattributeid = (SELECT trackedentityattributeid FROM trackedentityattribute WHERE uid = 'jWjSY7cktaQ')
  JOIN trackedentityattributevalue teav2 ON teav2.trackedentityinstanceid = tei.trackedentityinstanceid AND teav2.trackedentityattributeid = (SELECT trackedentityattributeid FROM trackedentityattribute WHERE uid = 'ZkNZOxS24k7')
  JOIN source ON teav1.value = source.full_name
  WHERE teav2.value = source.unit_tb_no;

----





---------------- ???
SELECT *
  FROM programstageinstance psi
    JOIN programinstance pi
      ON pi.programinstanceid = psi.programinstanceid
    JOIN trackedentityinstance tei
      ON pi.trackedentityinstanceid = tei.trackedentityinstanceid
    JOIN trackedentityattributevalue teav
      ON tei.trackedentityinstanceid = teav.trackedentityinstanceid
      AND teav.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}';


----------------


update programstageinstance psiupdate set status = 'COMPLETED',
    --set TRANSFER MODE to AUTOMATICALLY 
    eventdatavalues = jsonb_set(psiupdate.eventdatavalues, '{iup9aING8xC,value}', '"AUTOMATICALLY"')
    FROM programstageinstance psifrom


 SELECT
    psi.*,
    nextval('programstageinstance_sequence') as destpsiid, 
    (select programstageid from programstage where uid = 'tJ5SV8gfZaA') as destpsid,
    pi.programinstanceid as destinationpi
    
    
    FROM programstageinstance psi
    -- join trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' - District TB No, not in use
    JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7'
    JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ'
    -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA - District TB No, not in use
    /*
    join trackedentityattributevalue teav
    on teav.trackedentityattributeid = tea.trackedentityattributeid
    and teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}'
    */
    -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
    join trackedentityattributevalue teav2
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'
    -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
    join trackedentityattributevalue teav3
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'
    join trackedentityinstance tei on tei.trackedentityinstanceid = teav2.trackedentityinstanceid
    join programinstance pi on pi.trackedentityinstanceid = tei.trackedentityinstanceid and pi.deleted = false and pi.status = 'ACTIVE'
    join program p on p.programid = pi.programid and p.uid = 'wfd9K4dQVDR'

    --These are the event DEs that are used to check
    where psi.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    and (psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
    and psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';
