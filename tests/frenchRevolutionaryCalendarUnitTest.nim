import unittest
import nimcalcal

suite "testFrenchRevolutionarySmoke":
    test "testMidnightInParis":
        let d = fixed_from_gregorian(gregorian_date(1992, OCTOBER, 13)) 
        echo d, " ", midnight_in_paris(d)
        check midnight_in_paris(d).int == d + 1


when not defined(js):
    import parsecsv, streams, strutils
    suite "FrenchRevolutionaryAppendixCTestCase":
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



        test "testFrenchRevolutionary":
            for d in data:
                let fixed = parseInt(d[0])
                let fr = french_date(parseInt(d[32]), parseInt(d[33]), parseInt(d[34]))
                let frm = french_date(parseInt(d[35]), parseInt(d[36]), parseInt(d[37]))
                # french revolutionary original
                check fixed_from_french(fr) == fixed
                check french_from_fixed(fixed) == fr
                # french revolutionary modified
                check fixed_from_arithmetic_french(frm) == fixed
                check arithmetic_french_from_fixed(fixed) == frm




