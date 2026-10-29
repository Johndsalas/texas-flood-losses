-- Initial data extraction: pulls Texas claims and only the needed columns from the raw FEMA CSV, saves as parquet. 

COPY (
        SELECT
                    
        -- ID, time and place (Q1)

        id, 
        dateOfLoss, 
        yearOfLoss, 
        state, 
        countyCode, 
        reportedZipCode,

        -- dollars and non-payment (Q0, Q1)

        netBuildingPaymentAmount, 
        netContentsPaymentAmount,
        amountPaidOnBuildingClaim, 
        amountPaidOnContentsClaim,
        nonPaymentReasonBuilding, 
        nonPaymentReasonContents,
        
        -- data quality checks (Q0)
        
        originalConstructionDate, 
        elevationDifference,
        preFirmIndicator, 
        postFIRMConstructionIndicator,

        -- zones (Q2)
        
        ratedFloodZone, 
        floodZoneCurrent, 
        rateMethod,

        -- events (Q3)

        ficoNumber, 
        eventDesignationNumber, 
        floodEvent,

        -- building features and damage (Q4)

        buildingDamageAmount, 
        buildingPropertyValue,
        elevatedBuildingIndicator, 
        foundationType,

        -- coverage (Q5)

        totalBuildingInsuranceCoverage, 
        totalContentsInsuranceCoverage,
        buildingReplacementCost, 
        contentsDamageAmount,

        -- context

        occupancyType, 
        policyCount, 
        numberOfUnits,
        primaryResidenceIndicator, 
        causeOfDamage, 
        crsClassCode,
        condominiumCoverageTypeCode

        FROM read_csv('data/raw_claims_data.csv', sample_size = -1)

        WHERE state = 'TX'
      ) 
      
      TO 'data/tx_claims.parquet' (FORMAT parquet)