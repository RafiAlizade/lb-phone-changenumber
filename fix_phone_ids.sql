-- ============================================================================
-- CFX-CRP-CHANGEPHONENUMBER | FIX PHONE_PHONES ID -> OWNER_ID
-- ============================================================================
-- When LB-Phone runs with UniquePhones = false, each player's phone `id`
-- should match their CitizenID / Player Identifier (`owner_id`).
-- ============================================================================

-- STEP 1 (Safe Duplicate Cleanup):
-- If players have multiple older phone records from previous configurations,
-- this query preserves only the latest phone per owner and cleans up inactive duplicates
-- to prevent Primary Key collision:

DELETE p1 FROM `phone_phones` p1
INNER JOIN `phone_phones` p2 
WHERE p1.`owner_id` = p2.`owner_id` 
  AND (p1.`last_seen` < p2.`last_seen` OR (p1.`last_seen` = p2.`last_seen` AND p1.`id` < p2.`id`));

-- STEP 2:
-- Align all phone `id` fields to match `owner_id`:

UPDATE `phone_phones` SET `id` = `owner_id`;

-- Verification:
-- SELECT id, owner_id, phone_number, name, last_seen FROM `phone_phones`;
