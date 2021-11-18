/*
Flag events for review when:
  - District TB No is missing???
  - Unit TB No is matching but Name does not:
    Flag as "Check Name"
  - Event exist but no TEI matching Full name and TB Unit No is found:
    Flag as "No match"
  - Event Full name matches TEI Full name but NOT Unit TB No
    Flas as "Not Yet Transferred TB No Not Found"
*/

/*
 * TO CONSIDER, OR TODO
 * "Flagging" scripts does not check programstageid of event, should we?
 */

-- Set Transfer status = 'Check Name' for events with matching Unit TB No AND NO matching Full name
UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"Check Name"')
  FROM programstageinstance psi
  -- JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA - District TB No
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
  -- AND teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}' -- District TB No
  AND teav3 IS null -- Full Name
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';


-- Set Transfer status = 'No Match' for events with no matching Unit TB No AND Full name
UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"No Match"')
  FROM programstageinstance psi
  -- JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA -- District TB No
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
  -- teav IS null AND
  AND teav2 IS null AND teav3 IS null -- Unit TB No, Full name
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';


-- Set Transfer status = 'Not Yet Transferred TB No Not Found' for events with matching Full name AND NOT matching Unit TB No
UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"Not Yet Transferred TB No Not Found"')
  FROM programstageinstance psi
  --JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
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







---

/*
 * TESTS AND DRAFTS
 */


UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"Check Name"')
  SELECT *
  FROM programstageinstance psi
  -- JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA - District TB No
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
  WHERE 
  psiupdate.programstageinstanceid = psi.programstageinstanceid
  AND teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}' -- Unit TB No
  -- AND teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}' -- District TB No
  AND teav3 IS null -- Full Name
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';


UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"No Match"')
  SELECT *
  FROM programstageinstance psi
  -- JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA -- District TB No
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
  WHERE --psiupdate.programstageinstanceid = psi.programstageinstanceid
  -- teav IS null AND
  teav2 IS null AND teav3 IS null -- Unit TB No, Full name
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';


UPDATE programstageinstance psiupdate
  SET eventdatavalues = jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"Not Yet Transferred TB No Not Found"')
  SELECT *
  FROM programstageinstance psi
  --JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
    -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
  LEFT join trackedentityattributevalue teav2 
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'
  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
  LEFT join trackedentityattributevalue teav3 
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'
  WHERE --psiupdate.programstageinstanceid = psi.programstageinstanceid
  teav2 IS null -- where Unit TB No does not match
  AND teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' -- and name does match
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';








/*
 * OLD - WITH DISTRICT TB No
 */


-- Set Transfer status = 'No Match' for events with no matching Unit TB No AND District TB No AND Full name
UPDATE programstageinstance psi
  SET jsonb_set(psiupdate.eventdatavalues, '{iup9aING8xC,value}', '"No Match"')
  JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
  -- Match trackedentityattribute fPlDBVvpEJR with eventdatavalues eCy7sKTrwnA - District TB No
  LEFT JOIN trackedentityattributevalue teav
    on teav.trackedentityattributeid = tea.trackedentityattributeid
    and teav.value = psi.eventdatavalues#>>'{"eCy7sKTrwnA","value"}'
  -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
  LEFT join trackedentityattributevalue teav2 
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'
  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
  LEFT join trackedentityattributevalue teav3 
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'
  WHERE
  teav IS null AND teav2 IS null AND teav3 IS null
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';


-- Set Transfer status = 'Not Yet Transferred TB No Not Found' for events with matching Full name AND NOT matching Unit TB No
UPDATE programstageinstance psi
  SET jsonb_set(psiupdate.eventdatavalues, '{iup9aING8xC,value}', '"Not Yet Transferred TB No Not Found"')
  --JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
    -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
  LEFT join trackedentityattributevalue teav2 
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'
  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
  LEFT join trackedentityattributevalue teav3 
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'
  WHERE
  teav2 IS null -- where Unit TB No does not match
  AND teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' -- and name does match
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';



-- Set Transfer status = 'Not Yet Transferred TB No Not Found' for events with matching Full name AND NOT matching Unit TB No
UPDATE programstageinstance psi
  SET jsonb_set(psi.eventdatavalues, '{iup9aING8xC,value}', '"Not Yet Transferred TB No Not Found"')
  --JOIN trackedentityattribute tea on tea.uid = 'fPlDBVvpEJR' -- District TB No
  JOIN trackedentityattribute tea2 on tea2.uid = 'ZkNZOxS24k7' -- Unit TB No
  JOIN trackedentityattribute tea3 on tea3.uid = 'jWjSY7cktaQ' -- Full Name
    -- Match trackedentityattribute ZkNZOxS24k7 with eventdatavalues XupJDPkqWoL - Unit TB No
  LEFT join trackedentityattributevalue teav2 
    on teav2.trackedentityattributeid = tea2.trackedentityattributeid
    and teav2.value = psi.eventdatavalues#>>'{"XupJDPkqWoL","value"}'
  -- Match trackedentityattribute jWjSY7cktaQ with eventdatavalues bvuRnNr6INS - Full name
  LEFT join trackedentityattributevalue teav3 
    on teav3.trackedentityattributeid = tea3.trackedentityattributeid
    and teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}'
  WHERE
  teav2 IS null -- where Unit TB No does not match
  AND teav3.value = psi.eventdatavalues#>>'{"bvuRnNr6INS","value"}' -- and name does match
  AND psi.eventdatavalues#>>'{"MVQOgAxvNWh","value"}' IN ('EVENT_TRANSFER', 'PERMANENT_TRANSFER')
  AND psi.eventdatavalues#>>'{"iup9aING8xC","value"}' = 'NOTTRANSFERRED';