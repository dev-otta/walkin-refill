/*
 * Various support queries
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
    --UPDATE programstageinstance psiupdate
    --SET status = 'ACTIVE'
    SELECT psifrom.*
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
    JOIN programinstance pi on pi.trackedentityinstanceid = tei.trackedentityinstanceid and pi.deleted = false and pi.status = 'ACTIVE'

    WHERE psifrom.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    AND (psifrom.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
    AND psifrom.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'AUTOMATICALLY'
    AND psiupdate.programstageinstanceid = psifrom.programstageinstanceid

    RETURNING 
    nextval('programstageinstance_sequence') as destpsiid, 
    (select programstageid from programstage where uid = 'edyRc6d5Bts') as destpsid, 
    psifrom.*, 
    pi.programinstanceid as destinationpi )
)
SELECT * FROM transfer;