import unittest
import nimcalcal
import math
import tables

suite "BasicCodeTestCase":
    test "testNext":
        check next(0, proc(i:int):bool = i == 3) == 3
        check next(0, proc(i:int):bool = i == 0) == 0



    test "testFinal":
        check final(0, proc(i:int):bool = i == 3) == -1
        check final(0, proc(i:int):bool = i < 3)  == 2
        check final(0, proc(i:int):bool = i < 0)  == -1


    test "testSumma":
        check summa(proc(x:int):int = 1, 1, proc(i:int):bool = i<=4) == 4
        check summa(proc(x:int):int = 1, 0, proc(i:int):bool = i>=4) == 0
        check summa(proc(x:int):int = x ^ 2, 1, proc(i:int):bool = i <= 4) == 30


    test "testBinarySearch":
        var fx = proc(x:float64):float64 = x
        var fminusy = proc(x,y: float64):float64 = fx(x) - y 
        var y  = 1.0
        proc p[T](a, b:T):bool = abs(fminusy(0.5 * (a+b), y)) <= pow(10.0, -5.0)
        proc e[T](x:T):bool = fminusy(x, y) >= 0.0
        #  function y = f(x), f(x) = x, y0 = 1.0; solution is x0 = 1.0    
        var x0 = 1.0
            
        check binary_search(0.0, 3.1, p, e) - x0 <= pow(10.0, -5.0)
        # new function y = f(x), f(x) = x**2 - 4*x + 4, y0 = 0.0; solution x0=2.0
        y = 0.0
        x0 = 2.0
        fx = proc(x:float64):float64 = x ^ 2 - 4 * x + 4.0
        check binary_search(1.5, 2.5, p, e) - x0 <= pow(10.0, -5.0)



    test "testInvertAngular":
        # find angle theta such that tan(theta) = 1
        # assert that theta - pi/4 <= 10**-5
        check invert_angular(tan,
                             1.0,
                             0,
                             radians_from_degrees(60.0)) - 
                             radians_from_degrees(45.0) <= pow(10.0, -5.0)


    test "testSigma":
        let a = @[ 1, 2, 3, 4]
        let b = @[ 5, 6, 7, 8]
        let c = @[ 9,10,11,12]
        let ell = @[a,b,c]
        let bi  = proc(x:seq[int]):int = x[0] * x[1] * x[2]
        check sigma(ell, bi) == 780



    test "testPoly":
        check poly(0.0, [2.0, 2.0, 1.0]) == 2.0
        check poly(1.0, [2.0, 2.0, 1.0]) == 5.0



    test "testClockFromMoment":
        var c = clock_from_moment(3.5)
        check hour(c) == 12
        check minute(c) == 0
        check seconds(c) == 0
    
        c = clock_from_moment(3.75)
        check hour(c) == 18
        check minute(c) == 0
        check seconds(c) == 0
        
        c = clock_from_moment(3.8)
        check hour(c) == 19
        check minute(c) == 11
        check seconds(c) == 59


    test "testTimeFromClock":
        let epsilon = pow(10.0, -5.0)
        var x = time_from_clock(time_of_day(12, 0, 0)) 
        check abs(0.5 - x) < epsilon
        x = time_from_clock(time_of_day(18, 0, 0))
        check abs(0.75 - x) < epsilon
        x = time_from_clock(time_of_day(19, 12, 0))
        check abs(0.8 - x) < epsilon

when not defined(js):
    import parsecsv, streams, strutils
    suite "get weekday names from fixed dates in csv data file":
        test "Weekdays":
            var filename = "tests/dates1.csv"
            var s = newFileStream(filename)
            if s == nil:
                echo "can't open file"
                quit(1)
            var x = CsvParser()
            var data: seq[(int, string)]
            data = @[]
            open(x, s, filename)
            while readRow(x):
                data.add((parseInt(x.row[0]), x.row[1]))
            close(x)
            for d in data:
                let dwn = DAYS_OF_WEEK_NAMES[day_of_week_from_fixed(d[0])]
                #stderr.write($gregorian_from_fixed(d[0]) & " " & dwn, " " & d[1] & "\n")
                #stderr.write(dwn & " " & d[1] & "\n")
                check  dwn == d[1]

