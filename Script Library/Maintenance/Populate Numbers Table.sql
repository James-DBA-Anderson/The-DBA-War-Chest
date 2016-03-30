
-- Populate the Numbers table in the UtilityDB with 1m rows

BEGIN TRY
	BEGIN TRANSACTION;
		-- Empty the table
		TRUNCATE TABLE [dbo].[Numbers];

		;WITH cte_Ten
		AS
		(
			SELECT	n

			FROM	(
						VALUES	(1),
								(2),
								(3),
								(4),
								(5),
								(6),
								(7),
								(8),
								(9),
								(10)						 
					) AS Numbers(n)
		)

		INSERT	[dbo].[Numbers](n)
		SELECT	ROW_NUMBER() OVER(ORDER BY (SELECT 1))

		FROM		cte_Ten Ten1
		CROSS JOIN	cte_Ten Ten2 -- 100
		CROSS JOIN	cte_Ten Ten3 -- 1000
		CROSS JOIN	cte_Ten Ten4 -- 10000
		CROSS JOIN	cte_Ten Ten5 -- 100000
		CROSS JOIN	cte_Ten Ten6; -- 1000000

	COMMIT TRANSACTION;
END TRY
BEGIN CATCH;
	IF @@TRANCOUNT > 0
		ROLLBACK;

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	SELECT	@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH





