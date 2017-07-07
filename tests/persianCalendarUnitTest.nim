import unittest
import nimcalcal


when not defined(js):
    import strutils
    import readTestDataHelper

    suite "PersianAppendixCTestCase":
        setup:
            let data = readTestData("tests/dates3.csv")

        test "testPersian":
            for row in data:
                let rd = parseInt(row[0])
                let par = gregorian_date(parseInt(row[29]),
                                         parseInt(row[30]),
                                         parseInt(row[31]))
                let pas = gregorian_date(parseInt(row[26]),
                                         parseInt(row[27]),
                                         parseInt(row[28]))
                # persian arithmetic
                check fixed_from_arithmetic_persian(par) == rd
                check arithmetic_persian_from_fixed(rd) == par
                # persian astronomical
                check persian_from_fixed(rd) == pas
                check fixed_from_persian(pas) == rd




