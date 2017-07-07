import unittest
import nimcalcal


suite "BalineseSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check bali_pawukon_from_fixed(testvalue) ==
                balinese_date(true, 2, 1, 1, 3, 1, 2, 5, 7, 2)

    test "testConversionToFixed":
        check bali_on_or_before(
                balinese_date(true, 2, 1, 1, 3, 1, 2, 5, 7, 2),
                testvalue) ==
              testvalue

when not defined(js):
    import strutils
    import readTestDataHelper

    suite "BalineseAppendixCTestCase":
        setup:
            let data = readTestData("tests/dates3.csv")
    
        test "testBalinese":
            for d in data:
                let fixed = parseInt(d[0])
                let bd = balinese_date(if d[16] == "f": false else: true,
                                        parseInt(d[17]),
                                        parseInt(d[18]),
                                        parseInt(d[19]),
                                        parseInt(d[20]),
                                        parseInt(d[21]),
                                        parseInt(d[22]),
                                        parseInt(d[23]),
                                        parseInt(d[24]),
                                        parseInt(d[25]))
            
                check bali_pawukon_from_fixed(fixed) == bd



