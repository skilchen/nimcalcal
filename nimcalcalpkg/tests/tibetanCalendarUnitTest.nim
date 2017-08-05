import unittest
import nimcalcal


when not defined(js):
    import strutils
    import readTestDataHelper

    suite "TibetanAppendixCTestCase":
        setup:
            let data = readTestData("nimcalcalpkg/tests/dates4.csv")

        test "testTibetan":
            for row in data:
                let rd = parseInt(row[0])
                let td = tibetan_date(parseInt(row[32]),
                                      parseInt(row[33]),
                                      if row[34] == "f": false else: true,
                                      parseInt(row[35]),
                                      if row[36] == "f": false else: true)

                check fixed_from_tibetan(td) == rd
                check tibetan_from_fixed(rd) == td



