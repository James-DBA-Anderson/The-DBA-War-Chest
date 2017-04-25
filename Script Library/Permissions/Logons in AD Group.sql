
-- List Logons in AD Group
-- James Anderson
-- 2017-04-24

EXEC master..xp_logininfo 
	@acctname = 'AD Group',
	@option = 'members'