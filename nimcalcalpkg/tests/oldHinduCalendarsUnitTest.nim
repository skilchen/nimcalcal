import unittest
import nimcalcal


suite "OldHinduSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check old_hindu_solar_from_fixed(testvalue) ==
                hindu_solar_date(5046, 7, 29)
        check old_hindu_lunar_from_fixed(testvalue) ==
                old_hindu_lunar_date(5046, 8, false, 8)
        # FIXME (not sure the check is correct)
        check jovian_year(testvalue) == 32

    test "testConversionToFixed":
        check testvalue ==
            fixed_from_old_hindu_solar(hindu_solar_date(5046, 7, 29))
        check testvalue ==
            fixed_from_old_hindu_lunar(
                old_hindu_lunar_date(5046, 8, false, 8))

when not defined(js):
    import strutils
    import readTestDataHelper

    suite "OldHinduAppendixCTestCase":
        setup:
            let data = readTestData("nimcalcalpkg/tests/dates4.csv")

        test "testOldHindu":
            for row in data:
                let rd = parseInt(row[0])
                let ohs = hindu_solar_date(parseInt(row[9]),
                                           parseInt(row[10]),
                                            parseInt(row[11]))
                let ohl = old_hindu_lunar_date(parseInt(row[18]),
                                               parseInt(row[19]),
                                               if row[20] == "f": false else: true,
                                               parseInt(row[21]))
                # solar
                check fixed_from_old_hindu_solar(ohs) == rd
                check old_hindu_solar_from_fixed(rd) == ohs
                # lunisolar
                check fixed_from_old_hindu_lunar(ohl) == rd
                check old_hindu_lunar_from_fixed(rd) == ohl




