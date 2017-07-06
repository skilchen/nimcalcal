import unittest
import nimcalcal

suite "CopticSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check coptic_from_fixed(testvalue) == coptic_date(1662, 3, 3)

    test "testConversionToFixed":
        check testvalue == fixed_from_coptic(coptic_date(1662, 3, 3))


suite "EthiopicSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFrom":
        check ethiopic_from_fixed(testvalue) == ethiopic_date(1938, 3, 3)

    test "testConversionToFixed":
        check testvalue == fixed_from_ethiopic(ethiopic_date(1938, 3, 3))


when not defined(js):
    import strutils
    import readTestDataHelper 
    suite "FileBasedTests":
        setup:
            let data1 = readTestData("tests/dates1.csv")
            let data2 = readTestData("tests/dates2.csv")

        test "testCoptic":
            for d in data1:
                let fixed = parseInt(d[0])
                let cd = coptic_date(parseInt(d[24]), parseInt(d[25]), parseInt(d[26]))

                check coptic_from_fixed(fixed) == cd
                check fixed_from_coptic(cd) == fixed


        test "testEthiopic":
            for d in data2:
                let fixed = parseInt(d[0])
                let ed = ethiopic_date(parseInt(d[1]), parseInt(d[2]), parseInt(d[3]))

                # ethiopic day
                check ethiopic_from_fixed(fixed) == ed
                check fixed_from_ethiopic(ed) == fixed

