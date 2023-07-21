
/*
 * Walk in refill transfer script
 * 
 * The script is a series of SQL queries that are run in sequence as a single operation. The script has been divided into two sections with several parts each.
 * Section ONE deals with the transfer of eligible events to a matching tracked entity instance (TEI).
 * Section TWO deals with events set for transfer where a matching TEI is not found, flagging events by setting their transfer status to one of ["Check Name", "No match", "Not Yet Transferred TB No Not Found"]
 *
 * The queries aim to do the following:
 *
 * Section ONE
 * 1) Transfer eventdatavalues from TB-Refill event program to TREATMENT and LAB program stages of TB-Refill tracker program.
 * 2) Flag source events as completed when LAB data is transferred or use event STATUS and TRANSFER STATUS to mark source event for transfer of lab results when they are available.
 * 3) Transfer LAB results for events where TREATMENT has already transferred.
 * 4) Update ownership of TEI on PERMANENT_TRANSFER
 *
 * Section TWO
 * 1) Set Transfer status = 'Check Name' for events with matching Unit TB No AND NO matching Full name
 * 2) Set Transfer status = 'No Match' for events with no matching Unit TB No AND no matching Full name
 * 3) Set Transfer status = 'Not Yet Transferred TB No Not Found' for events with matching Full name AND NOT matching Unit TB No
 *
 */

/*
 * Section ZERO
 * Function declarations
 */

CREATE OR REPLACE FUNCTION send_message (recipient_orgunitid bigint, message_messagetype varchar(255), message_messagesubject varchar(255), message_messagetext text) RETURNS VOID
    LANGUAGE plpgsql
AS
$$
DECLARE
    --TABLE_RECORD RECORD;
  recipient bigint;
  --mc_sequence bigint := nextval('messageconversation_sequence');
  --m_sequence bigint := nextval('message_sequence');
  --um_sequence int := nextval('usermessage_sequence');
BEGIN

DROP TABLE IF EXISTS temptransfermessage;
CREATE TEMP TABLE temptransfermessage (
    messageconversationid bigint,
    time timestamp without time zone,
    messageid bigint,
    usermessageid int,
    userid bigint
);

FOR recipient IN SELECT ui.userinfoid FROM userinfo ui
  JOIN users u ON ui.userinfoid = u.userid
  JOIN usergroupmembers ugm ON ugm.userid = ui.userinfoid
  JOIN usergroup ug ON ug.usergroupid = ugm.usergroupid AND ugm.userid = ui.userinfoid
  JOIN usermembership um ON um.userinfoid = ui.userinfoid
  JOIN organisationunit ou ON ou.organisationunitid = um.organisationunitid
  WHERE ug.uid = 'phS5ScyDEYj' -- UID of userGroup whose members will recieve messages
  AND ou.organisationunitid = recipient_orgunitid

  LOOP    
    INSERT INTO temptransfermessage SELECT 
      nextval('messageconversation_sequence'),
      now(),
      nextval('message_sequence'),
      nextval('usermessage_sequence'),
      recipient;
  END LOOP; 

INSERT INTO messageconversation SELECT --(messageconversationid, uid, messagecount, created, lastupdated, subject, messagetype, priority, status, user_assigned, lastsenderid, lastmessage, userid)
    s1.messageconversationid as messageconversationid,
    generate_uid() as uid,
    1 as messagecount,
    s1.time as created,
    s1.time as lastupdated,
    message_messagesubject as subject,
    message_messagetype as messagetype,
    'NONE' as priority,
    'NONE' as status,
    NULL as user_assigned,
    NULL as lastsenderid,
    s1.time as lastmessage,
    s1.userid as userid
    FROM temptransfermessage s1
    ;

INSERT INTO message SELECT
    s1.messageid as messageid,
    generate_uid() as uid,
    now() as created,
    now() as lastupdated,
    message_messagetext as messagetext,
    FALSE as internal,
    NULL as metadata,
    s1.userid as userid
    FROM temptransfermessage s1
    ;

INSERT INTO messageconversation_messages SELECT
    s1.messageconversationid as messageconversationid,
    1 as sort_order,
    s1.messageid as messageid
    FROM temptransfermessage s1
    ;

-- Repeat for all recipients
INSERT INTO usermessage SELECT
    s1.usermessageid as usermessageid,
    gen_random_uuid() as usermessagekey,
    s1.userid as userid,
    false as isread,
    false as isfollowup
    FROM temptransfermessage s1
    ;

INSERT INTO messageconversation_usermessages SELECT
    s1.messageconversationid as messageconversationid,
    s1.usermessageid as usermessageid
    FROM temptransfermessage s1
    ;

END
$$;



/*
 * Section ONE
 * 1) Transfer
 */
BEGIN;

WITH transfer as(

  SELECT
    psi.*,
    nextval('programstageinstance_sequence') as treatmentpsiid,
    nextval('programstageinstance_sequence') as labpsiid,
    (select programstageid from programstage where uid = 'tJ5SV8gfZaA') as treatmentpsid,
    (select programstageid from programstage where uid = 'edyRc6d5Bts') as labpsid,
    pi.programinstanceid as destinationpi,
    pi.organisationunitid as sourceorgunit,
    psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' as fullname,
    psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}' as tbnumber
    
    FROM programstageinstance psi
    -- JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No, not in use
    JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
    JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full name
    
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

    -- Join in the tracked entity instance and its enrollment/programinstance
    join trackedentityinstance tei on tei.trackedentityinstanceid = teav2.trackedentityinstanceid
    join programinstance pi on pi.trackedentityinstanceid = tei.trackedentityinstanceid and pi.deleted = false and pi.status = 'ACTIVE'
    join program p on p.programid = pi.programid and p.uid = 'wfd9K4dQVDR'

    -- Make sure to select only events belonging to the source program that have TRANSFER REQUEST set to 'EVENT_TRANSFER' or 'PERMANENT_TRANSFER' and TRANSFER STATUS 'NOTTRANSFERRED'
    where psi.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    and (psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
    and psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED' 
),

insert_treatment AS (
  insert into programstageinstance (programstageinstanceid,uid,programinstanceid,programstageid,executiondate,organisationunitid,status,created,lastupdated,attributeoptioncomboid,deleted,storedby,createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo )
    (select                           treatmentpsiid,generate_uid(),destinationpi,  treatmentpsid,      executiondate,organisationunitid,'COMPLETED',now(),  now(), attributeoptioncomboid,FALSE  ,'SCRIPT',createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo
    from transfer where destinationpi is not null)
),
insert_lab AS (
  insert into programstageinstance (programstageinstanceid,uid           ,programinstanceid,programstageid,executiondate,organisationunitid,status     ,created,lastupdated,attributeoptioncomboid,deleted,storedby,createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo )
    (select                         labpsiid              ,generate_uid(),destinationpi    ,labpsid       ,executiondate,organisationunitid,'COMPLETED',now()  ,now()      ,attributeoptioncomboid,FALSE  ,'SCRIPT',createdatclient,lastupdatedatclient,geometry,lastsynchronized,eventdatavalues,assigneduserid,createdbyuserinfo,lastupdatedbyuserinfo
    from transfer where destinationpi is not null)
),
message_targetou AS (
SELECT send_message(organisationunitid, 'PRIVATE', 'Patient transfer', CONCAT('Patient has been transferred: ',tbnumber, ' ', fullname))
  from transfer where destinationpi is not null
)
SELECT send_message(sourceorgunit, 'PRIVATE', 'Patient transfer', CONCAT('Patient has been transferred: ',tbnumber, ' ', fullname))
  from transfer where destinationpi is not null;



/*
 * 2) Status update query:
 */
-- Having transferred the events above, we now need to set TRANSFER STATUS to AUTOMATICALLY AND complete the source events
-- In the case where we have transferred an event with no lab results (eventdatavalues#>>'{"WTz4HSqoE5E","value"}' IS NULL)
-- we set status = ACTIVE and TRANSFER STATUS to AUTOMATICALLY for later transfer of lab results.
-- !! Note: Do not run this query without having run queries above; it updates regardless of wheter events are transferred or not.
UPDATE programstageinstance psiupdate
    -- when eventprogram.WTz4HSqoE5E (Follow up lab Results) exists : SET status = 'COMPLETED'; ELSE 'ACTIVE'
    SET status = CASE
        WHEN psifrom.eventdatavalues#>>'{"WTz4HSqoE5E","value"}' IS NULL OR
            psifrom.eventdatavalues#>>'{"WTz4HSqoE5E","value"}' = ''
            THEN 'ACTIVE' ELSE 'COMPLETED' END,
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
    join trackedentityattributevalue teav2
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psifrom.eventdatavalues#>>'{"XupJDPkqWoL","value"}'

    -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
    join trackedentityattributevalue teav3
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psifrom.eventdatavalues#>>'{"bvuRnNr6INS","value"}'

    -- Join in the tracked entity instance and its enrollment/programinstance
    join trackedentityinstance tei on tei.trackedentityinstanceid = teav2.trackedentityinstanceid
    join programinstance pi on pi.trackedentityinstanceid = tei.trackedentityinstanceid and pi.deleted = false and pi.status = 'ACTIVE'

    -- Make sure to only update events belonging to TB-Refill program stage that have TRANSFER REQUEST set to 'EVENT_TRANSFER' or 'PERMANENT_TRANSFER' and TRANSFER STATUS 'NOTTRANSFERRED'
    where psifrom.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    and (psifrom.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
    and psifrom.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED'
    and psiupdate.programstageinstanceid = psifrom.programstageinstanceid;



/*
 * 3) Lab result transfer:
 */
-- We should now have transferread all eligible events and flagged them as 'AUTOMATICALLY' transferred.
-- For those events 'AUTOMATICALLY' transferred yet still have status = 'ACTIVE' we want to transfer lab results
-- and mark event with status = 'COMPLETE'
WITH transfer AS (
    UPDATE programstageinstance psiupdate
    SET status = 'COMPLETED'
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

    -- Join in the tracked entity instance and its enrollment/programinstance
    JOIN trackedentityinstance tei on tei.trackedentityinstanceid = teav2.trackedentityinstanceid
    JOIN programinstance pi on pi.trackedentityinstanceid = tei.trackedentityinstanceid and pi.deleted = false and pi.status = 'ACTIVE'

    -- Make sure we select only source events that have TRANSFER REQUEST set to 'EVENT_TRANSFER' or 'PERMANENT_TRANSFER', have already been transferred (TRANSFER STATUS = 'AUTOMATICALLY')
    -- , have event status 'ACTIVE' AND have LAB results (WTz4HSqoE5E IS NOT NULL)
    WHERE psifrom.programstageid = (SELECT programstageid from programstage WHERE uid = 'qZ43tA7bpir')
    AND (psifrom.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER'))
    AND psifrom.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'AUTOMATICALLY'
    AND psifrom.status = 'ACTIVE'
    AND psifrom.eventdatavalues#>>'{"WTz4HSqoE5E","value"}' IS NOT NULL
    AND psiupdate.programstageinstanceid = psifrom.programstageinstanceid

    RETURNING 
    (select programstageid from programstage where uid = 'edyRc6d5Bts') as destpsid, 
    psifrom.*, 
    pi.programinstanceid as destinationpi
),
update_lab as (
UPDATE programstageinstance psitracker
    SET eventdatavalues = psitracker.eventdatavalues || transfer.eventdatavalues
  FROM transfer
  WHERE destinationpi IS NOT NULL
    AND psitracker.programstageid = transfer.destpsid
    AND psitracker.programinstanceid = destinationpi
)
SELECT send_message(organisationunitid, 'PRIVATE', 'Lab results transfer', CONCAT('Lab results transferred: ',eventdatavalues#>>'{"XupJDPkqWoL","value"}', ' ', eventdatavalues#>>'{"bvuRnNr6INS","value"}'))
  from transfer where destinationpi is not null;
;


/*
 * 4) Update TEI ownership on PERMANENT_TRANSFER:
 */
-- Once done with transfers above, select events from event program that are set to permanent transfer, MVQOgAxvNWh='PERMANENT_TRANSFER',
-- and have been transferred, iup9aING8xC='AUTOMATICALLY', then match these to TEI on Full name, bvuRnNr6INS; and Unit TB No, XupJDPkqWoL
-- and update program ownership (trackedentityprogramowner), setting organisationunitid to org. unit specified in event.
WITH source AS (
  SELECT psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' full_name,
  psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}' unit_tb_no,
  orgu.organisationunitid targetorgu,
  tea2.trackedentityattributeid tea2id,
  tea3.trackedentityattributeid tea3id,
  tei.trackedentityinstanceid sourceteiid

  FROM programstageinstance psi
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full name
  
  -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
  join trackedentityattributevalue teav2
  on teav2.trackedentityattributeid = tea2.trackedentityattributeid
  and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'

  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
  join trackedentityattributevalue teav3
  on teav3.trackedentityattributeid = tea3.trackedentityattributeid
  and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'
	
  -- Join with trackedentityinstance to identify trackedentityprogramowner
	JOIN trackedentityinstance tei on tei.trackedentityinstanceid = teav2.trackedentityinstanceid
	
  -- Join with trackedentityprogramowner in order to filter out previously transferred TEIs in WHERE clause
	JOIN trackedentityprogramowner tpo on tpo.programid = (SELECT programid FROM program WHERE uid = 'wfd9K4dQVDR')
		AND tpo.trackedentityinstanceid = tei.trackedentityinstanceid

  -- Join with organisationunit to get organisationunitid for easy reference  	
	JOIN organisationunit orgu on orgu.uid = psi.eventdatavalues#>>'{"JpvpfVIjK7x","value"}'
		
  -- Select only source events that are set for PERMANENT_TRANSFER and have previously had eventdatavalues transferred (TRANSFER STATUS = 'AUTOMATICALLY')
  WHERE psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' = 'PERMANENT_TRANSFER'
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'AUTOMATICALLY'
  AND psi.status = 'COMPLETED'
  
  -- Select only events that have not previously had TEI ownership updated; Where trackedentityprogramowner does not equal JpvpfVIjK7x (Transferred/Referred to Facility)
  AND tpo.organisationunitid != (SELECT organisationunitid FROM organisationunit WHERE uid = psi.eventdatavalues#>>'{"JpvpfVIjK7x","value"}')
)
UPDATE trackedentityprogramowner tpo
  SET organisationunitid = source.targetorgu -- (SELECT organisationunitid FROM organisationunit WHERE uid = source.transfer_to_orgunit)
  FROM trackedentityinstance tei
  JOIN source ON tei.trackedentityinstanceid = source.sourceteiid
  JOIN trackedentityattributevalue teav2 ON teav2.trackedentityinstanceid = tei.trackedentityinstanceid AND teav2.trackedentityattributeid = source.tea2id -- (SELECT trackedentityattributeid FROM trackedentityattribute WHERE uid = 'ZkNZOxS24k7')
  JOIN trackedentityattributevalue teav3 ON teav3.trackedentityinstanceid = tei.trackedentityinstanceid AND teav3.trackedentityattributeid = source.tea3id -- (SELECT trackedentityattributeid FROM trackedentityattribute WHERE uid = 'jWjSY7cktaQ')
  
  WHERE teav2.value = source.unit_tb_no
  AND tpo.trackedentityinstanceid = tei.trackedentityinstanceid;

COMMIT;

/*
 * Section TWO
 *
 * Flag events for review when:
 * - Unit TB No is matching but Name does not:
 *   Flag as "Check Name"
 * - Event exist but no TEI matching Full name and TB Unit No is found:
 *   Flag as "No match"
 * - Event matches on TEI Full name, but NOT Unit TB No
 *   Flag as "Not Yet Transferred TB No Not Found"
 */

/*
 * 1) Set Transfer status = 'Check Name' for events with matching Unit TB No AND NO matching Full name
 */
UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"Check Name"')
  FROM 
  send_message(12111, 'PRIVATE', 'Patient transfer', CONCAT('Patient has been transferred: ','tbnumber', ' ', 'fullname')),
  programstageinstance psi
  -- JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name

  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA - District TB No, not in use
  /*
  LEFT JOIN trackedentityattributevalue teav
    on teav.trackedentityattributeid = tea.trackedentityattributeid
    and teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}'
  */

  -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
  LEFT join trackedentityattributevalue teav2 
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'

  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
  LEFT join trackedentityattributevalue teav3 
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'

  WHERE psiupdate.programstageinstanceid = psi.programstageinstanceid
  AND teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}' -- Unit TB No
  AND teav3 IS null -- Full Name
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';
  

/*
 * 2) Set Transfer status = 'No Match' for events with no matching Unit TB No AND no matching Full name
 */
UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"No Match"')
  FROM programstageinstance psi
  -- JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name

  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA -- District TB No, not in use
  /*
  LEFT JOIN trackedentityattributevalue teav
    on teav.trackedentityattributeid = tea.trackedentityattributeid
    and teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}'
  */

  -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL -- Unit TB No
  LEFT join trackedentityattributevalue teav2 
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'

  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS -- Full name
  LEFT join trackedentityattributevalue teav3 
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'

  WHERE psiupdate.programstageinstanceid = psi.programstageinstanceid
  AND teav2 IS null AND teav3 IS null -- Unit TB No, Full name
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';


/*
 * 3) Set Transfer status = 'Not Yet Transferred TB No Not Found' for events with matching Full name AND NOT matching Unit TB No
 */
UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"Not Yet Transferred TB No Not Found"')
  FROM programstageinstance psi
  --JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name

  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA -- District TB No, not in use
  /*
  LEFT JOIN trackedentityattributevalue teav
    on teav.trackedentityattributeid = tea.trackedentityattributeid
    and teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}'
  */

  -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
  LEFT join trackedentityattributevalue teav2 
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'
  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
  LEFT join trackedentityattributevalue teav3 
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'
  WHERE psiupdate.programstageinstanceid = psi.programstageinstanceid
  AND teav2 IS null -- where Unit TB No does not match
  AND teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' -- and name does match
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';

/*
 * END
 */
