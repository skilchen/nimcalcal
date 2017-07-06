import unittest
import nimcalcal

when not defined(js):
    import strutils
    import readTestDataHelper

    type hinduTestData = object
        fixed: int
        mhs: calDate
        ohs: calDate
        ahs: calDate
        mhl: hinduLDate
        ahl: hinduLDate

    proc parseModernHinduData(data: seq[seq[string]]): seq[hinduTestData] =
        result = @[]

        for d in data:
            var r: hinduTestData
            r.fixed = parseInt(d[0])
            r.ohs = hindu_solar_date(parseInt(d[9]), parseInt(d[10]), parseInt(d[11]))
            r.mhs = hindu_solar_date(parseInt(d[12]), parseInt(d[13]), parseInt(d[14]))
            r.ahs = hindu_solar_date(parseInt(d[15]), parseInt(d[16]), parseInt(d[17]))
            r.mhl = hindu_lunar_date(parseInt(d[22]), parseInt(d[23]), 
                                     if d[24] == "f": false else: true,
                                     parseInt(d[25]),
                                     if d[26] == "f": false else: true)
            r.ahl = hindu_lunar_date(parseInt(d[27]), parseInt(d[28]), 
                                     if d[29] == "f": false else: true,
                                     parseInt(d[30]),
                                     if d[31] == "f": false else: true)

            result.add(r)
        return result

    suite "ModernHinduAppendixCTestCase":
        setup:
            let data = readTestData("tests/dates4.csv")
            let data1 = parseModernHinduData(data)

        test "testHinduSolarModernToFixed":
            for d in data1:
                # hindu solar
                #    modern
                check fixed_from_hindu_solar(d.mhs) == d.fixed

        test "testHinduSolarModernFromFixed":
            for d in data1:
                # hindu solar
                #    modern
                check hindu_solar_from_fixed(d.fixed) == d.mhs

        test "testHinduSolarAstronomicalToFixed":
            for d in data1:
                #    astronomical
                check fixed_from_astro_hindu_solar(d.ahs) == d.fixed

        test "testHinduSolarAstronomicalFromFixed":
            for d in data1:
                #    astronomical
                check astro_hindu_solar_from_fixed(d.fixed) == d.ahs

        test "testHinduLunisolarModernToFixed":
            for d in data1:
                # hindu lunisolar
                #    modern
                check fixed_from_hindu_lunar(d.mhl) == d.fixed

        test "testHinduLunisolarModernFromFixed":
            for d in data1:
                # hindu lunisolar
                #    modern
                check hindu_lunar_from_fixed(d.fixed) == d.mhl

        test "testHinduLunisolarAstronomicalToFixed":
            for d in data1:
                # hindu lunisolar
                #    astronomical
                check fixed_from_astro_hindu_lunar(d.ahl) == d.fixed

        test "testHinduLunisolarAstronomicalFromFixed":
            for d in data1:
                # hindu lunisolar
                #    astronomical
                check astro_hindu_lunar_from_fixed(d.fixed) == d.ahl
