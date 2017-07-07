import unittest
import nimcalcal 


suite "MayanSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check mayan_long_count_from_fixed(testvalue) ==
                         mayan_long_count_date(12, 16, 11, 16, 9)
        check mayan_long_count_from_fixed(0) ==
                         mayan_long_count_date(7, 17, 18, 13, 2)
        check mayan_haab_from_fixed(testvalue) ==
                         mayan_haab_date(11, 7)
        check mayan_tzolkin_from_fixed(testvalue) ==
                         mayan_tzolkin_date(11, 9)

    test "testConversionToFixed":
        check testvalue ==
            fixed_from_mayan_long_count(
                mayan_long_count_date(12, 16, 11, 16, 9))
        check rd(0) ==
            fixed_from_mayan_long_count(
                mayan_long_count_date(7, 17, 18, 13, 2))
        check mayan_haab_on_or_before(mayan_haab_date(11, 7), testvalue) == testvalue
        check mayan_tzolkin_on_or_before(
                mayan_tzolkin_date(11, 9), testvalue) == testvalue

suite "AztecSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check aztec_xihuitl_from_fixed(testvalue) == aztec_xihuitl_date(2, 1)

    test "testConversionToFixed":
        check aztec_xihuitl_on_or_before(aztec_xihuitl_date(2, 1), testvalue) == testvalue

when not defined(js):
    import strutils
    import readTestDataHelper

    suite "MayanAppendixCTestCase":
        setup:
            let data = readTestdata("tests/dates2.csv")

        test "testMayan":
            for row in data:
                let rd = parseInt(row[0])
                let mlc = mayan_long_count_date(parseInt(row[20]), parseInt(row[21]),
                                                parseInt(row[22]), parseInt(row[23]),
                                                parseInt(row[24]))
                let mh = mayan_haab_date(parseInt(row[25]), parseInt(row[26]))
                let mt = mayan_tzolkin_date(parseInt(row[27]), parseInt(row[28]))

                # mayan (long count)
                check mayan_long_count_from_fixed(rd) == mlc
                check fixed_from_mayan_long_count(mlc) == rd
                # mayan (haab)
                check mayan_haab_from_fixed(rd) == mh
                # mayan (tzolkin)
                check mayan_tzolkin_from_fixed(rd) == mt

        test "testAztec":
            for row in data:
                let rd = parseInt(row[0])
                let ax = aztec_xihuitl_date(parseInt(row[29]), parseInt(row[30]))
                let at = aztec_tonalpohualli_date(parseInt(row[31]), parseInt(row[32]))

                # aztec xihuitl
                check aztec_xihuitl_from_fixed(rd) == ax
                # aztec tonalpohualli
                check aztec_tonalpohualli_from_fixed(rd) == at


