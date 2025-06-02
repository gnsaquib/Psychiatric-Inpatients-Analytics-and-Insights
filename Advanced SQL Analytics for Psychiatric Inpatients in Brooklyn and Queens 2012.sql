SELECT * FROM brooklyn_queens_hospital_inpatient_discharges; -- To see the whole table

-- Analysis of length of stay and total costs for patients with schizophrenia spectrum and mood disorders based on demographic grouping.

WITH psych_patients AS (
	SELECT ccs_diagnosis_description 
	FROM brooklyn_queens_hospital_inpatient_discharges
	WHERE ccs_diagnosis_description IN (
		'Schizophrenia and other psychotic disorders',
        'Mood disorders',
        'Alcohol-related disorders',
        'Delirium, dementia, and amnestic and other cognitive disorders',
        'Substance-related disorders',
        'Personality disorders',
        'Impulse control disorders, NEC',
        'Adjustment disorders',
        'Anxiety disorders',
        'Developmental disorders',
        'Screening and history of mental health and substance abuse codes',
        'Suicide and intentional self-inflicted injury'
	)
) -- CTE used to extract all diagnosis related to patients with schizophrenia spectrum and mood disorders

SELECT
	age_group, gender, race, ethnicity, -- demographic categories
	COUNT(*) AS patient_count,
	ROUND(AVG(length_of_stay),2) AS length_of_stay, -- taking average of length_of_stay
	ROUND(AVG(total_costs), 2) AS total_costs  -- taking average of total_costs
FROM brooklyn_queens_hospital_inpatient_discharges tb
JOIN psych_patients pp ON pp.ccs_diagnosis_description = tb.ccs_diagnosis_description
GROUP BY age_group, gender, race, ethnicity -- grouping based on all demographic categories
ORDER BY patient_count DESC; -- ordering based on the total number of patients in each demographic group


-- Comparing Emergency Department usage patterns between psychiatric and non-psychiatric admissions.

SELECT
	CASE -- using CASE statement to categorize
		WHEN ccs_diagnosis_description IN (
		'Schizophrenia and other psychotic disorders',
        'Mood disorders',
        'Alcohol-related disorders',
        'Delirium, dementia, and amnestic and other cognitive disorders',
        'Substance-related disorders',
        'Personality disorders',
        'Impulse control disorders, NEC',
        'Adjustment disorders',
        'Anxiety disorders',
        'Developmental disorders',
        'Screening and history of mental health and substance abuse codes',
        'Suicide and intentional self-inflicted injury'
	)
		THEN 'Psychiatric'
		ELSE 'Non-Psychiatric'
	END AS diagnosis_category,
	emergency_department_indicator,
	COUNT(*) AS admission_count,
	ROUND(AVG(length_of_stay), 2) AS length_of_stay -- taking the average of length_of_stay for the categories
FROM brooklyn_queens_hospital_inpatient_discharges
WHERE emergency_department_indicator = 'Y' -- indicating usage of emergency department
GROUP BY diagnosis_category, emergency_department_indicator;

-- Analysis of severity and mortality risk for psychiatric conditions.

SELECT
	ccs_diagnosis_description,
	apr_severity_of_illness_description,
	apr_risk_of_mortality,
	COUNT(*) AS case_count,
	ROUND(AVG(total_costs), 2) AS total_costs, -- taking the average of total_costs
	ROUND(AVG(length_of_stay), 2) AS length_of_stay -- taking the average of length_of_stay
FROM brooklyn_queens_hospital_inpatient_discharges
WHERE apr_mdc_description = 'Mental Diseases and Disorders' -- filter for psychiatric
GROUP BY ccs_diagnosis_description, apr_severity_of_illness_description, apr_risk_of_mortality
ORDER BY case_count DESC;


-- Identifying high risk and high cost psychiatric patients.
WITH psych_patients AS (
    SELECT *
    FROM brooklyn_queens_hospital_inpatient_discharges
    WHERE ccs_diagnosis_description IN (
        'Schizophrenia and other psychotic disorders',
        'Mood disorders',
        'Alcohol-related disorders',
        'Delirium, dementia, and amnestic and other cognitive disorders',
        'Substance-related disorders',
        'Personality disorders',
        'Impulse control disorders, NEC',
        'Adjustment disorders',
        'Anxiety disorders',
        'Developmental disorders',
        'Screening and history of mental health and substance abuse codes',
        'Suicide and intentional self-inflicted injury'
    )
) -- CTE used to extract all diagnosis related to patients with schizophrenia spectrum and mood disorders
SELECT
    age_group, gender, race, ccs_diagnosis_description, length_of_stay, total_costs,
    -- average length of stay for this diagnosis, above average will be high risk
    AVG(length_of_stay) OVER (PARTITION BY ccs_diagnosis_description) AS avg_los_by_diag,
    -- average cost for this diagnosis, above average will be high cost
    AVG(total_costs) OVER (PARTITION BY ccs_diagnosis_description) AS avg_cost_by_diag,
    -- flag if this patient is above average for both metrics
    CASE -- using CASE statement to categorize the age groups.
        WHEN length_of_stay > AVG(length_of_stay) OVER (PARTITION BY ccs_diagnosis_description)
         AND total_costs > AVG(total_costs) OVER (PARTITION BY ccs_diagnosis_description)
        THEN 'High-Risk High-Cost'
        ELSE 'Typical'
    END AS risk_cost_flag
FROM psych_patients
ORDER BY risk_cost_flag, total_costs DESC;