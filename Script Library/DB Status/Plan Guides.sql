
-- DBA War Chest 
-- Plan Guides
-- 2016-02-10 

-- Display all plan guides and attempt to validate them.
-- If the validation query returns errors check here for possible reasons 
-- http://thedatabaseavenger.com/2015/11/plan-guides-and-the-risk-of-validation-with-built-in-functions/


SELECT	*
FROM	sys.plan_guides;

-- Attempt to validate plan guides
SELECT		plan_guide_id
			, msgnum
			, severity
			, state
			, message

FROM		sys.plan_guides
CROSS APPLY fn_validate_plan_guide(plan_guide_id);