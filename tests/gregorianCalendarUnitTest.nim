import unittest
import nimcalcal

suite "Test the Gregorian Calendar":
    setup:
        let testvalue = 710347
        let aDate = gregorian_date(1945, NOVEMBER, 12)
        let myDate = gregorian_date(1967, JANUARY, 30)
        let aLeapDate = gregorian_date(1900, MARCH, 1)

    test "ConversionFromFixed":
        check gregorian_from_fixed(testvalue) == aDate
            

    test "testConversionToFixed":
        check testvalue == fixed_from_gregorian(aDate)

    test "testLeapYear":
        check is_gregorian_leap_year(2000)
        check is_gregorian_leap_year(1900) != true

    test "testDayNumber":
        check day_number(myDate) == 30
        check day_number(aLeapDate) == 60

when not defined(js):
    import strutils
    import readTestDataHelper

    suite "Test the Gregorian Calendar with Test Data from csv File":
        setup:
            let data = readTestData("tests/dates1.csv")

        test "testGregorian":
            for d in data:
                let grd = gregorian_date(parseInt(d[4]), parseInt(d[5]), parseInt(d[6]))
                let fixed = parseInt(d[0])
                check gregorian_from_fixed(fixed) == grd
                check fixed_from_gregorian(grd) == fixed
                check gregorian_year_from_fixed(fixed) == standard_year(grd)

        test "testAltGregorian":
            for d in data:
                let grd = gregorian_date(parseInt(d[4]), parseInt(d[5]), parseInt(d[6]))
                let fixed = parseInt(d[0])

                check alt_gregorian_from_fixed(fixed) == grd
                check alt_fixed_from_gregorian(grd) == fixed
                check alt_gregorian_year_from_fixed(fixed) == standard_year(grd)
                    
