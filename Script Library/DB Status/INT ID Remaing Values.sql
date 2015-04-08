
-- DBA War Chest 
-- Show INT ID Remaining Values
-- 2015-03-26

-- Show the remaining amount of values each auto increment INT ID column has remaining.
-- If a column is close to using all it's vales the DBA needs to consider altering the
-- column to a BIGINT or resetting the current identity value.

SELECT		Seed
			, Increment
			, CurrentIdentity
			, TABLE_NAME AS [Table]
			, DataType
			, MaxPosValue 
			, FLOOR((MaxPosValue -CurrentIdentity)/Increment) AS Remaining
			, 100-100*((CurrentIdentity-Seed)/Increment+1) / FLOOR((MaxPosValue - Seed) /Increment+1) AS PercentUnAllocated

FROM		(
				SELECT		IDENT_SEED(TABLE_SCHEMA + '.' + TABLE_NAME) AS Seed 
							, IDENT_INCR(TABLE_SCHEMA + '.' + TABLE_NAME) AS Increment 
							, IDENT_CURRENT(TABLE_SCHEMA + '.' + TABLE_NAME) AS CurrentIdentity 
							, TABLE_SCHEMA + '.' + TABLE_NAME AS TABLE_NAME 
							, UPPER(c.DATA_TYPE) AS DataType 
							, FLOOR(t.MaxPosValue/IDENT_INCR(TABLE_SCHEMA + '.' + TABLE_NAME)) * IDENT_INCR(TABLE_SCHEMA + '.' + TABLE_NAME) AS MaxPosValue

				FROM		INFORMATION_SCHEMA.COLUMNS AS c
				JOIN		(	
								SELECT	name AS Data_Type 
										, POWER(CAST(2 AS VARCHAR), ( max_length * 8 ) - 1) AS MaxPosValue

								FROM	sys.types
								WHERE	name LIKE '%Int'
							) t ON c.DATA_TYPE = t.Data_Type

				WHERE		COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1
			) AS T1

ORDER BY	PercentUnAllocated ASC