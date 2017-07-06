import unittest
import nimcalcal

suite "JulianSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check julian_from_fixed(testvalue) == julian_date(1945, OCTOBER, 30)
        check roman_from_fixed(testvalue) ==
            roman_date(1945, NOVEMBER, KALENDS, 3, is_julian_leap_year(1945))

    test "testConversionToFixed":
        check testvalue ==
                    fixed_from_julian(julian_date(1945, OCTOBER, 30))
        check testvalue ==
            fixed_from_roman(roman_date(1945, NOVEMBER, KALENDS, 3,
                                        is_julian_leap_year(1945)))

    test "testLeapYear":
        check is_julian_leap_year(2000)
        check is_julian_leap_year(1900)

suite "RomanSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check roman_from_fixed(testvalue) ==
            roman_date(1945, NOVEMBER, KALENDS, 3, false)

    test "testConversionToFixed":
        check testvalue ==
                    fixed_from_roman(roman_date(1945,
                                                NOVEMBER,
                                                KALENDS,
                                                3,
                                                false))

when not defined(js):
    import strutils
    import readTestDataHelper
    suite "JulianDayAppendixCTestCase":
        setup:
            let data = readTestData("tests/dates1.csv")

        test "testJulianDay":
            for d in data:
                let fixed = parseint(d[0])
                let jd = parseFloat(d[2])
                let mjd = parseInt(d[3])
                # julian day
                check jd_from_fixed(fixed) == jd
                check fixed_from_jd(jd) == fixed
                # modified julian day
                check mjd_from_fixed(fixed) == mjd
                check fixed_from_mjd(mjd) == fixed



    suite "JulianAppendixCTestCase":
        setup:
            let data = readTestData("tests/dates1.csv")

        test "testJulian":
            for d in data:
                let fixed = parseInt(d[0])
                let jdt = julian_date(parseInt(d[10]), parseInt(d[11]), parseInt(d[12]))
                let jrn = roman_date(parseInt(d[13]),
                                     parseInt(d[14]),
                                     parseInt(d[15]),
                                     parseInt(d[16]),
                                     if d[17] == "f": false else: true)
                # julian date
                check julian_from_fixed(fixed) == jdt
                check fixed_from_julian(jdt) == fixed
                # julian date, roman name
                check roman_from_fixed(fixed) == jrn
                check fixed_from_roman(jrn) == fixed


