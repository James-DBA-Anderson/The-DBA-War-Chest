
-- DBA War Chest 
-- Linked Servers 
-- 2015-05-19

-- Show all linked servers

SELECT	*

FROM	sys.servers s
WHERE	s.server_id > 0 -- server_id 1 = local instance