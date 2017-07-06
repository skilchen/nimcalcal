import unittest
import nimcalcal


suite "HebrewSmokeTestCase":
    setup:
        let testvalue = 710347

    test "testConversionFromFixed":
        check hebrew_from_fixed(testvalue) == hebrew_date(5706, KISLEV, 7)

    test "testConversionToFixed":
        check testvalue == fixed_from_hebrew(hebrew_date(5706, KISLEV, 7))


suite "HebrewHolidaysTestCase":
    test "testBirkathHaHama":
        check len(birkath_ha_hama(1925)) != 0
        check len(birkath_ha_hama(1926)) == 0
        check len(birkath_ha_hama(1925+28)) != 0

    test "testTzomTevet":
        ## test tzom tevet (Tevet 10): see page 104
        check len(tzom_tevet(1982)) == 2
        check len(tzom_tevet(1984)) == 0

    test "testPossibleHebrewDays":
        ## see page 110, Calendrical Calculations, 3rd edition.
        check possible_hebrew_days(SHEVAT, 15) ==
                    @[THURSDAY, SATURDAY, MONDAY, TUESDAY, WEDNESDAY]


when not defined(js):
    import parsecsv, streams, strutils
    suite "HebrewAppendixCTestCase":
        setup:
            echo "reading test data..."
            var filename = "tests/dates3.csv"
            var s = newFileStream(filename)
            if s == nil:
                echo "can't open file"
                quit(1)
            var x = CsvParser()
            var data: seq[seq[string]]
            data = @[]
            open(x, s, filename)
            while readRow(x):
                var myrow: seq[string] = @[]
                for item in x.row:
                    myrow.add(item)
                data.add(myrow)
            close(x)    

        test "testHebrew":
            for d in data:
                let fixed = parseInt(d[0])
                let hd = hebrew_date(parseInt(d[1]), parseInt(d[2]), parseInt(d[3]))
                let ho = hebrew_date(parseInt(d[4]), parseInt(d[5]), parseInt(d[6]))

                check fixed_from_hebrew(hd) == fixed
                check hebrew_from_fixed(fixed) == hd
                # observational
                check observational_hebrew_from_fixed(fixed) == ho
                check fixed_from_observational_hebrew(ho) == fixed

