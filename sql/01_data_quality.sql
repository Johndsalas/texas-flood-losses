-- ============================================================
-- 01_data_quality.sql
-- Texas Flood Insurance Claims (FEMA NFIP Redacted Claims v3)
-- ============================================================
-- Purpose: check the raw claims table (Texas extract, 394,204 rows)
-- for duplicates, missing values, invalid codes and implausible values
-- before cleaning.
--
-- This file only reads data. It does not change the raw table. Each
-- check ends with a finding and a decision (keep, null, drop or flag),
-- and those decisions are carried out in 02_clean.sql.
--
-- Checks, in order:
--   1. id uniqueness
--   2. Paid claim definition
--   3. Error-delete claims (non-payment reason 98)
--   4. County codes
--   5. Zip codes
--   6. Large payments against coverage caps
--   7. Construction dates
-- ============================================================


-- ------------------------------------------------------------
-- 1. id uniqueness
-- Check:    id is unique and never null
-- Finding:  394,204 rows, 394,204 unique ids, 0 nulls
-- Decision: id is unique, so each row can be treated as a separate claim
-- ------------------------------------------------------------

-- Returns total number of rows, unique ids, and nulls

SELECT 
        count(*) as total_rows,
        count(distinct id) as unique_ids, 
        count(*) - count(id) as nulls
FROM
        claims;
                

-- ------------------------------------------------------------
-- 2. Paid claim definition
-- Definition: A claim is paid if its net building payment or net
--             contents payment is positive. The net columns are used
--             instead of the gross amountPaid columns because they
--             subtract recoveries, so they reflect the actual cost of
--             the claim
-- Check:      Every claim with no positive net payment (zero, negative
--             or null in both columns) should have a non-payment reason
--             code
-- Finding:    950 rows have no positive net payment and no non-payment
--             reason code, 0.2% of all 394,204 claims
-- Decision:   Keep the paid definition. Keep and flag the 950 rows,
--             since they add no positive dollars to any total, and the
--             missing reason could be an open claim, a recording gap or
--             something else. Drop the gross amountPaid columns in the
--             clean and use the net columns for all payment totals
-- ------------------------------------------------------------

-- Returns unpaid claims with and without a non-payment reason code

select 
    case 
        when 
            nonPaymentReasonBuilding is not null
            or
            nonPaymentReasonContents is not null
            or
            netBuildingPaymentAmount > 0 
            or
            netContentsPaymentAmount > 0
            then 'Paid or Reason Recorded'
            else 'No Payment, No Reason'
            end as payment_status,

     count(*) as "number_of_claims"
from 
            claims
group by 
            payment_status;


-- ------------------------------------------------------------
-- 3. Error-delete claims (nonPaymentReasonBuilding, nonPaymentReasonContents)
-- Check:      How many claims carry non-payment reason '98' (error-delete
--             claim) on either the building or contents reason, and how
--             many net dollars those rows carry
-- Finding:    5,867 rows have reason '98' on at least one side, 1.5% of all
--             394,204 claims. Payments on the other side total about
--             $9.4 million building (0.07% of net building dollars) and
--             $1.1 million contents (0.03% of net contents dollars)
-- Decision:   Drop the '98' rows in the clean. FEMA codes them as
--             "Error-delete claim," marking them as errors to be deleted,
--             so the whole row is junk, and dropping them barely moves
--             dollar totals
-- ------------------------------------------------------------

-- Returns the number of error-delete rows and their share of net dollars

 select 
        count(case when nonPaymentReasonContents = '98' or nonPaymentReasonBuilding = '98' then 1 end) as count,
        sum(case when nonPaymentReasonContents = '98' then netBuildingPaymentAmount end) as total_building_paid,
        round(sum(case when nonPaymentReasonContents = '98' then netBuildingPaymentAmount end) / sum(netBuildingPaymentAmount) * 100,3) as percent_building_paid,
        sum(case when nonPaymentReasonBuilding = '98' then netContentsPaymentAmount end) as total_contents_paid,
        round(sum(case when nonPaymentReasonBuilding = '98' then netContentsPaymentAmount end) / sum(netContentsPaymentAmount) * 100,3) as percent_contents_paid
from 
        claims;


-- ------------------------------------------------------------
-- 4. County codes (countyCode)
-- Check:      How many claims have a null county code, and how many
--             have a code outside Texas (Texas county FIPS codes start
--             with 48)
-- Finding:    2,128 rows have a null county code, 0.5% of all 394,204
--             claims. 1 row has a non-Texas code (22029, Louisiana)
-- Decision:   Keep all rows, since the state field marks them as Texas
--             claims. Set the non-Texas code to null in the clean, so
--             these rows count in Texas totals but not in any county.
--             Note in limitations: FEMA says countyCode may not be the
--             property's actual county
-- ------------------------------------------------------------

-- 4a. Returns total rows, non-Texas county codes (including nulls),
-- null county codes, and non-Texas county codes excluding nulls

select 
        count(*) as total,
        count(*) - sum(case when countyCode like '48%' then 1 else 0 end) as non_texas,
        sum(case when countyCode is null then 1 else 0 end) as nulls,
        non_texas - nulls as non_texas_non_nulls
from 
        claims;

-- 4b. Lists each non-Texas county code and how many rows have it

select 
        countyCode, 
        count(*) as non_texas_counts
from 
        claims
where   
        countyCode not like '48%'
group by 
        countyCode;

-- ------------------------------------------------------------
-- 5. Zip codes (reportedZipCode)
-- Check:      How many claims have a null zip, and how many have a zip
--             outside Texas (Texas zips start with 75 to 79, 733 or 885)
-- Finding:    5,116 rows have a null zip, 1.3% of all 394,204 claims.
--             9 rows have non-Texas zips: neighboring states (Arkansas,
--             Oklahoma, Louisiana, Mississippi) plus placeholder-like
--             values (11111, 70000, and 96799, which is American Samoa)
-- Decision:   Keep all rows, since the state field marks them as Texas
--             claims. Set the 9 non-Texas zips to null in the clean, so
--             these rows count in Texas totals but are left out of
--             zip-level results, along with the null-zip rows
-- ------------------------------------------------------------

-- 5a. Returns non-Texas zips (including nulls), null zips, and
-- non-Texas zips excluding nulls

select 
        count(*) - sum(case when reportedZipCode like '75%'  or
                                 reportedZipCode like '76%'  or
                                 reportedZipCode like '77%'  or
                                 reportedZipCode like '78%'  or
                                 reportedZipCode like '79%'  or
                                 reportedZipCode like '733%' or
                                 reportedZipCode like '885%'  
                                 then 1 else 0 end) as non_texas,
        sum(case when reportedZipCode is null then 1 else 0 end) as nulls,
        non_texas - nulls as non_texas_non_nulls
from 
        claims;

-- 5b. Lists each non-Texas zip and how many rows have it

select 
        reportedZipCode, 
        count(*) as non_texas_counts      
from 
        claims
where   
        reportedZipCode not  like '75%'  and
        reportedZipCode not  like '76%'  and
        reportedZipCode not  like '77%'  and
        reportedZipCode not  like '78%'  and
        reportedZipCode not  like '79%'  and
        reportedZipCode not  like '733%' and
        reportedZipCode not  like '885%'
group by 
        reportedZipCode;


-- ------------------------------------------------------------
-- 6. Large payments against coverage caps
-- Check: do the largest net payments fit under the NFIP cap for
-- their occupancy type?
-- ------------------------------------------------------------

-- 6a. [what this query tests]
[query];
-- Finding: [one line]

-- 6b. [what this query tests]
[query];
-- Finding: [one line]

-- Decision: [overall decision for the section]


-- ------------------------------------------------------------
-- 7. Construction dates
-- Check: do the largest net payments fit under the NFIP cap for
-- their occupancy type?
-- ------------------------------------------------------------

-- 6a. [what this query tests]
[query];
-- Finding: [one line]

-- 6b. [what this query tests]
[query];
-- Finding: [one line]

-- Decision: [overall decision for the section]