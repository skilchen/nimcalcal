import unittest
import nimcalcal


suite "ISOSmokeTestCase":
    setup:
        let testvalue = 710347
        let aDate = iso_date(1945, 46, 1)

    test "testConversionFromFixed":
        check iso_from_fixed(testvalue) == aDate

    test "testConversionToFixed":
        check testvalue == fixed_from_iso(aDate)

when not defined(js):
    import strutils
    import readTestDataHelper

    suite "IsoAppendixCTestCase":
        setup:
            let data = readTestData("nimcalcalpkg/tests/dates1.csv")
        
        test "testIso":
            for d in data:
                let isod = iso_date(parseInt(d[7]), parseInt(d[8]), parseInt(d[9]))
                let fixed = parseInt(d[0])            
                check iso_from_fixed(fixed) == isod
                check fixed_from_iso(isod) == fixed




