
-- DBA War Chest 
-- Alter The Database Owner
-- 2015-04-07 

-- The database owner logon should not be a personal account that may get
-- disabled once the user leaves the company. SA is also not the best choice.
-- A dedicated user account the refuses logon could be a good option.

ALTER AUTHORIZATION ON DATABASE::Alere to sa;

