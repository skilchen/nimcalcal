import unittest
import nimcalcal

suite "Test Easter Calculations":
  test "Easter and orthodox Easter 2017 on the same date 2017-04-16":
    let ed = gregorian_from_fixed(easter(2017))
    let oed = gregorian_from_fixed(orthodox_easter(2017))
    check $ed == "2017-04-16"
    check $oed == "2017-04-16"

  test "Easter and orthodox Easter 2028 again on the same date 2028-04-16":
    let ed = gregorian_from_fixed(easter(2017))
    let oed = gregorian_from_fixed(orthodox_easter(2017))
    check $ed == "2017-04-16"
    check $oed == "2017-04-16"

when not defined(js):    
  import strutils
  import readTestDataHelper
  suite "Test Easter Calculation with Test Data from csv File":
    setup:
      let data = readTestData("nimcalcalpkg/tests/dates3.csv")

    test "testEaster":
        for d in data:
          var d1: seq[int]
          d1 = @[]
          d1.setLen(d.len())
          for i,_ in pairs(d1):
            try:
              d1[i] = parseInt(d[i])
            except:
              continue
          let fixed = d1[0]
          let ge = gregorian_date(d1[10], d1[11], d1[12])
          let je = gregorian_date(d1[7], d1[8], d1[9])
          let ae = gregorian_date(d1[13], d1[14], d1[15])

          check gregorian_from_fixed(orthodox_easter(
                       gregorian_year_from_fixed(fixed))) == je

          check gregorian_from_fixed(alt_orthodox_easter(
                       gregorian_year_from_fixed(fixed))) == je

          check gregorian_from_fixed(easter(
                       gregorian_year_from_fixed(fixed))) == ge

          check gregorian_from_fixed(astronomical_easter(
                       gregorian_year_from_fixed(fixed))) == ae


