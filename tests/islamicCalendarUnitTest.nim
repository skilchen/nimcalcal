import unittest
import nimcalcal

suite "IslamicSmokeTestCase":
    setUp:
        let testvalue = 710347

    test "testConversionFromFixed":
        check islamic_from_fixed(testvalue) == islamic_date(1364, 12, 6)

    test "testConversionToFixed":
        check testvalue == fixed_from_islamic(islamic_date(1364, 12, 6))

when not defined(js):
    import parsecsv, streams, strutils
    suite "IslamicAppendixCTestCase":
        setup:
            echo "reading test data..."
            var filename = "tests/dates2.csv"
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

        test "testIslamic":
            for d in data:
                let isd = islamic_date(parseInt(d[4]), parseInt(d[5]), parseInt(d[6]))
                let iod = islamic_date(parseInt(d[7]), parseInt(d[8]), parseInt(d[9]))
                let fixed = parseInt(d[0])            

                check islamic_from_fixed(fixed) == isd
                check fixed_from_islamic(isd) == fixed
                # islamic (observational)
                check fixed_from_observational_islamic(iod) == fixed
                check observational_islamic_from_fixed(fixed) == iod

