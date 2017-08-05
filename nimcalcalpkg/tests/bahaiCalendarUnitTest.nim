import unittest
import nimcalcal


when not defined(js):
    import readTestDataHelper
    import strutils

    suite "BahaiAppendixCTestCase":
        setup:
            let data = readTestData("nimcalcalpkg/tests/dates2.csv")

        test "testBahai":
            for d in data:
                let fixed = parseInt(d[0])
                let bd = bahai_date(parseInt(d[10]), parseInt(d[11]), parseInt(d[12]),
                                    parseInt(d[13]), parseInt(d[14]))
                let bf = bahai_date(parseInt(d[15]), parseInt(d[16]), parseInt(d[17]),
                                    parseInt(d[18]), parseInt(d[19]))
                # bahai
                check bahai_from_fixed(fixed) == bd
                check fixed_from_bahai(bd) == fixed
                # bahai future
                check future_bahai_from_fixed(fixed) == bf
                check fixed_from_future_bahai(bf) == fixed




