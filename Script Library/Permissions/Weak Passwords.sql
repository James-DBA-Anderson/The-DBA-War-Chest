IF OBJECT_ID('tempdb..#weakpasswords') IS NOT NULL
	DROP TABLE #weakpasswords;
create table #weakpasswords ([ServerName] sysname
							,[LoginName] sysname
							,[Password] varchar(max)
							,default_database_name sysname
							,is_policy_checked int
							,is_expiration_checked int
							,database_owner varchar(max))

DECLARE @WeakPwdList TABLE (WeakPwd NVARCHAR(255))
--Define weak password list
--Use @@Name if users password contain their name
-- Ref: http://security.blogoverflow.com/category/password/
-- Ref: http://www.smartplanet.com/blog/business-brains/the-25-worst-passwords-of-2011-8216password-8216123456-8242/20065
INSERT INTO @WeakPwdList (WeakPwd)
SELECT ''
UNION
SELECT '123'
UNION
SELECT '1234'
UNION
SELECT '12345'
UNION
SELECT '123456'
UNION
SELECT '654321'
UNION
SELECT '12345678'
UNION
SELECT '1234567'
UNION
SELECT '123456789'
UNION
SELECT '111111'
UNION
SELECT '123123'
UNION
SELECT 'abc'
UNION
SELECT 'abc123'
UNION
SELECT 'default'
UNION
SELECT 'guest'
UNION
SELECT '@@Name123'
UNION
SELECT '@@Name'
UNION
SELECT '@@Name@@Name'
UNION
SELECT 'admin'
UNION
SELECT 'Administrator'
UNION
SELECT 'admin123'
UNION
SELECT 'P@ssw0rd1'
UNION
SELECT 'Dealogic01'
UNION
SELECT 'newyork01'
UNION
SELECT 'Password'
UNION
SELECT 'iloveyou'
UNION
SELECT 'Qwerty'
UNION
SELECT 'Qw3rty'
UNION
SELECT 'rockyou'
UNION
SELECT 'Liverpool'
UNION
SELECT 'yorkshire'
UNION
SELECT 'MyPassword'
UNION
SELECT 'banana'
UNION
SELECT '6anana'
UNION
SELECT 'monkey'
UNION
SELECT 'letmein'
UNION
SELECT 'trustno1'
UNION
SELECT 'dragon'
UNION
SELECT 'drag0n1'
UNION
SELECT 'baseball'
UNION
SELECT 'passw0rd'
UNION
SELECT 'shadow'
UNION
SELECT 'superman'
UNION
SELECT 'qazwsx'
UNION
SELECT 'michael'
UNION
SELECT 'football'
UNION
SELECT 'ashley'
UNION
SELECT 'bailey'
UNION
SELECT 'INCORRECT'

insert into #weakpasswords
SELECT @@servername AS [ServerName]
	,sql_logins.NAME AS [LoginName]
	,CASE 
		WHEN PWDCOMPARE(REPLACE(t2.WeakPwd, '@@Name', REVERSE(sql_logins.NAME)), password_hash) = 0
			THEN REPLACE(t2.WeakPwd, '@@Name', sql_logins.NAME)
		ELSE REPLACE(t2.WeakPwd, '@@Name', REVERSE(sql_logins.NAME))
		END AS [Password]
	,sql_logins.default_database_name
	,sql_logins.is_policy_checked
	,sql_logins.is_expiration_checked
	--,sql_logins.is_disabled
	,(
		SELECT suser_sname(owner_sid)
		FROM sys.databases
		WHERE databases.NAME = sql_logins.default_database_name
		) AS database_owner
FROM sys.sql_logins
INNER JOIN @WeakPwdList t2 ON (
		PWDCOMPARE(t2.WeakPwd, password_hash) = 1
		OR PWDCOMPARE(REPLACE(t2.WeakPwd, '@@Name', sql_logins.NAME), password_hash) = 1
		OR PWDCOMPARE(REPLACE(t2.WeakPwd, '@@Name', REVERSE(sql_logins.NAME)), password_hash) = 1
		)
WHERE sql_logins.is_disabled = 0
ORDER BY sql_logins.NAME

--- report the weak passwords that we found
select * from #weakpasswords