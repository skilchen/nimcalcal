import unittest
import nimcalcal


when not defined(js):
  import strutils
  import readTestDataHelper
  import math

  suite "ChineseAppendixCTestCase":
    setup:
      let data = readTestData("nimcalcalpkg/tests/dates4.csv")

    test "testChinese":
        for d in data:
          let fixed = parseInt(d[0])
          let cd = chinese_date(parseInt(d[1]),
                                parseInt(d[2]),
                                parseInt(d[3]),
                                if d[4] == "f": false else: true,
                                parseInt(d[5]))
          let cn = (parseInt(d[6]), parseInt(d[7]))
          let ms = parseFloat(d[8])

          check fixed_from_chinese(cd) == fixed
          check chinese_from_fixed(fixed) == cd
          check chinese_day_name(fixed) == cn
          check abs(major_solar_term_on_or_after(fixed) - ms) < pow(1.0, -6.0)





