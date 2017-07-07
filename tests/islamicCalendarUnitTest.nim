import unittest
import nimcalcal

suite "IslamicSmokeTestCase":
    setUp:
        let testvalue = 710347

    test "testConversionFromFixed":
        check islamic_from_fixed(testvalue) == islamic_date(1364, 12, 6)

    test "testConversionToFixed":
        check testvalue == fixed_from_islamic(islamic_date(1364, 12, 6))

when not defined(js):
    import strutils
    import readTestDataHelper

    suite "IslamicAppendixCTestCase":
        setup:
            let data = readTestData("tests/dates2.csv")

        test "testIslamic":
            for d in data:
                let isd = islamic_date(parseInt(d[4]), parseInt(d[5]), parseInt(d[6]))
                let iod = islamic_date(parseInt(d[7]), parseInt(d[8]), parseInt(d[9]))
                let fixed = parseInt(d[0])            

                check islamic_from_fixed(fixed) == isd
                check fixed_from_islamic(isd) == fixed
                # islamic (observational)
                check fixed_from_observational_islamic(iod) == fixed
                check observational_islamic_from_fixed(fixed) == iod

