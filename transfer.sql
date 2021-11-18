

/*
 * Walk in refill transfer script
 * 
 * The script is a series of SQL queries that are run in sequence as a single operation. The queries aim to do the following:
 * 1) Transfer ¤TREATMENT¤ and ¤LAB¤
 * 2) Flag events as completed or for further processing
 * 3) Transfer ¤LAB¤ when ¤TREATMENT¤ is already transferred
 * 4) Update ownership of TEI on PERMANENT_TRANSFER
 */

-- A small sql function to return a random uid
-- suitable for use in dhis2
-- Bob Jolliffe 18 March 2015
CREATE OR REPLACE FUNCTION uid()
RETURNS text AS $$
  SELECT substring('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' 
    FROM (random()*51)::int +1 for 1) || 
    array_to_string(ARRAY(SELECT substring('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' 
       FROM (random()*61)::int + 1 FOR 1) 
   FROM generate_series(1,10)), '') 
$$ LANGUAGE sql;

BEGIN;

WITH transfer_treatment as(

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
    and psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED' 
    --and psiupdate.programstageinstanceid = psifrom.programstageinstanceid
    -- And psi Home Facility vQpn1BfawIR = psiupdate orgUnit -- prevents transfer when TB-refill event was registered with "Home Facility" = "Adilang HC III" and TEI registered at, and with ownership at, "Adilang HC III". I am confused by the "Home Facility" and "Transferred/Referred to Facility". This might be a good check to have, but how should it work?
    -- and psi.eventdatavalues#>>'{"vQpn1BfawIR","value"}' = (SELECT uid FROM organisationunit WHERE psiupdate.organisationunitid = organisationunit.organisationunitid)
),

transfer_lab AS (

    SELECT
      psi.*,
      nextval('programstageinstance_sequence') as destpsiid, 
      (select programstageid from programstage where uid = 'edyRc6d5Bts') as destpsid,
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
    where
      psi.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
      and (psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
      and psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED' 
      -- and psiupdate.programstageinstanceid = psi.programstageinstanceid
      -- And psi Home Facility vQpn1BfawIR = psiupdate orgUnit -- prevents transfer when TB-refill event was registered with "Home Facility" = "Adilang HC III" and TEI registered at, and with ownership at, "Adilang HC III". I am confused by the "Home Facility" and "Transferred/Referred to Facility". This might be a good check to have, but how should it work?
      -- and psi.eventdatavalues#>>'{"vQpn1BfawIR","value"}' = (SELECT uid FROM organisationunit WHERE psiupdate.organisationunitid = organisationunit.organisationunitid)
),

insert_treatment AS (
  insert into programstageinstance (programstageinstanceid,uid,programinstanceid,programstageid,executiondate,organisationunitid,status,created,lastupdated,attributeoptioncomboid,deleted,storedby,createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo )
    (select                           destpsiid             ,uid(),destinationpi,  destpsid,      executiondate,organisationunitid,'COMPLETED',now(),  now(), attributeoptioncomboid,FALSE  ,'SCRIPT',createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo
    from transfer_treatment where destinationpi is not null)
)--,

--insert_lab AS (
  insert into programstageinstance (programstageinstanceid,uid,programinstanceid,programstageid,executiondate,organisationunitid,status,created,lastupdated,attributeoptioncomboid,deleted,storedby,createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo )
    (select                           destpsiid             ,uid(),destinationpi,  destpsid,      executiondate,organisationunitid,'COMPLETED',now(),  now(), attributeoptioncomboid,FALSE  ,'SCRIPT',createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo
    from transfer_lab where destinationpi is not null);
--)


-- Having transferred the events above, we now need to set TRANSFER MODE to AUTOMATICALLY AND complete the events
-- TODO: Make sure to only complete events where lab results have been transferred!!

update programstageinstance psiupdate set status = 'COMPLETED',
    --set TRANSFER MODE to AUTOMATICALLY 
    eventdatavalues = jsonb_set(psiupdate.eventdatavalues, '{iup9aING8xC,value}', '"AUTOMATICALLY"')
    FROM programstageinstance psifrom
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
    and psiupdate.programstageinstanceid = psifrom.programstageinstanceid;


-- Update TEI ownership on PERMANENT_TRANSFER:
-- Once done with transfer above, select events from event program that are set to permanent transfer, MVQOgAxvNWh='PERMANENT_TRANSFER',
-- and have been transferred, iup9aING8xC='AUTOMATICALLY', then match these to TEI on Full name, bvuRnNr6INS, and Unit TB No, XupJDPkqWoL
-- and update program ownership, trackedentityprogramowner, setting organisationunitid to org. unit specified in event.
-- TODO: Make sure this doesn't run more than once
WITH source AS (
SELECT psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' full_name,
  psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}' unit_tb_no,
  psi.eventdatavalues#>>'{"JpvpfVIjK7x","value"}' transfer_to_orgunit
  FROM programstageinstance psi
  WHERE psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' = 'PERMANENT_TRANSFER'
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'AUTOMATICALLY'
  AND psi.status = 'COMPLETED')

UPDATE trackedentityprogramowner tpo
  SET organisationunitid = (SELECT organisationunitid FROM organisationunit WHERE uid = source.transfer_to_orgunit)
  FROM trackedentityinstance tei
  JOIN trackedentityattributevalue teav1 ON teav1.trackedentityinstanceid = tei.trackedentityinstanceid AND teav1.trackedentityattributeid = (SELECT trackedentityattributeid FROM trackedentityattribute WHERE uid = 'jWjSY7cktaQ')
  JOIN trackedentityattributevalue teav2 ON teav2.trackedentityinstanceid = tei.trackedentityinstanceid AND teav2.trackedentityattributeid = (SELECT trackedentityattributeid FROM trackedentityattribute WHERE uid = 'ZkNZOxS24k7')
  JOIN source ON teav1.value = source.full_name
  WHERE teav2.value = source.unit_tb_no
  AND tpo.trackedentityinstanceid = tei.trackedentityinstanceid;

COMMIT;





/*
 * Script ends here!
 * Below are tests and other stuff
 */

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
