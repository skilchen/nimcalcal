import unittest
import nimcalcal
import math

suite "TimeAndAstronomySmokeTestCase":
    setup:
        let rd = [-214193.0, -61387.0, 25469.0, 49217.0, 171307.0, 210155.0, 253427.0,
              369740.0, 400085.0, 434355.0, 452605.0, 470160.0, 473837.0, 507850.0,
              524156.0, 544676.0, 567118.0, 569477.0, 601716.0, 613424.0, 626596.0,
              645554.0, 664224.0, 671401.0, 694799.0, 704424.0, 708842.0, 709409.0,
              709580.0, 727274.0, 728714.0, 744313.0, 764652.0]

        let declinations = [341.009933681, 344.223866057, 344.349150723,
                        343.080796014, 6.111045686, 23.282088850,
                        11.054626067, 20.772095601, 350.530615797,
                        26.524557874, 24.624220236, 341.329137381,
                        22.952455871, 28.356788216, 11.708349719,
                        17.836387256, 1.234462343, 342.613034686,
                        339.494416096, 10.077195527, 356.273352051,
                        10.933004147, 333.162727246, 12.857424363,
                        342.981182734, 8.352097710, 342.717593219,
                        359.480653210, 339.868605556, 6.747953072,
                        15.403930316, 5.935073706, 6.502803786]

        let right_ascensions = [243.344057675, 204.985406451, 210.404938685,
                            292.982801046, 157.347243474, 109.710580543,
                            38.206587532, 99.237553669, 334.622772431,
                            92.594013257, 77.002562902, 275.265641321,
                            132.240141523, 89.495057657, 21.938682002,
                            51.336108524, 189.141475514, 323.504045205,
                            317.763636501, 146.668234288, 183.868193626,
                            143.441024476, 251.771505962, 154.432825924,
                            288.759213491, 24.368877399, 291.218608152,
                            190.563965149, 285.912816020, 152.814362172,
                            50.014265486, 26.456502208, 177.918419842]

        let lunar_altitudes = [-11.580406490, -13.996642398, -72.405467670,
                           -26.949751162, 60.491536818, -32.333449636,
                           43.325012802, -28.913935286, 20.844069354,
                           -9.603298107, -13.290409748, 20.650429381,
                           -9.068998404, -24.960604514, -34.865669400,
                           -40.121041983, -50.193172697, -39.456259107,
                           32.614203610, -46.078519304, -51.828340409,
                           -42.577971851, -15.990046584, 28.658077283,
                           22.718206310, 61.618573945, -26.504789606,
                           32.371736207, -38.544325288, 31.594345546,
                           -28.348377620, 30.478724056, -43.754783219]

        let dusks = [-214193.22, -61387.297, 25468.746, 49216.734,
                 171306.7, 210154.78, 253426.7, 369739.78,
                 400084.8, 434354.78, 452604.75, 470159.78,
                 473836.78, 507849.8, 524155.75, 544675.7,
                 567117.7, 569476.7, 601715.75, 613423.75,
                 626595.75, 645553.75, 664223.75, 671400.7,
                 694798.75, 704423.75, 708841.7, 709408.75,
                 709579.7, 727273.7, 728713.7, 744312.7,
                 764651.75]


    test "testDeclination":
        for i in rd.low..rd.high:
            let lamb = lunar_longitude(rd[i])
            let beta = lunar_latitude(rd[i])
            let alpha = declination(rd[i], beta, lamb)
            check abs(alpha - declinations[i]) < pow(1.0, -7.0)

    test "testRightAscension":
        for i in rd.low..rd.high:
            let lamb = lunar_longitude(rd[i])
            let beta = lunar_latitude(rd[i])
            let alpha = right_ascension(rd[i], beta, lamb)
            check abs(alpha - right_ascensions[i]) < 1e-7

    test "testLunarAltitude":
        for i in rd.low..rd.high:
            let alpha = lunar_altitude(rd[i], JAFFA)
            check abs(alpha - lunar_altitudes[i]) <  1e-6

    test "testDusk":
        for i in rd.low..rd.high:
            let du = dusk(rd[i] - 1, JAFFA, 4.5.float64)
            check abs(du - dusks[i]) < 1e-0


suite "AstronomicalAlgorithmsTestCase":
    test "testEclipticalFromEquatorial":
        # from the values in the Ch 13 Astronomical Algorithms
        let (ra, de) = equatorial_from_ecliptical(113.215630, 6.684170, 23.4392911)
        check abs(ra - 116.328942)  < 1e-5
        check abs(de - 28.026183) < 1e-6


    test "testEquatorialFromEcliptical":
        # from the values in the Ch 13 Astronomical Algorithms
        let (lo, la) = ecliptical_from_equatorial(116.328942, 28.026183, 23.4392911)
        check abs(lo - 113.215630'f64) < 1e-6
        check abs(la - 6.684170'f64) < 1e-6


    test "testHorizontalFromEquatorial":
        # from the values in the Ch 13 Astronomical Algorithms
        let (A, h) = horizontal_from_equatorial(64.352133, -6.719892, angle(38, 55, 17))
        check abs(A - 68.0337) < 1e-4
        check abs(h - 15.1249) < 1e-4


    test "testEquatorialFromHorizontal":
        # from the values in the Ch 13 Astronomical Algorithms
        let (H, d) = equatorial_from_horizontal(68.0337, 15.1249, angle(38, 55, 17))
        check abs(H - 64.352133) < 1e-4
        check abs(d - normalized_degrees(angle(-6,-43,-11.61))) < 1e-4


    test "testUrbanaWinter":
        # from the values in the book pag 191
        check abs(urbana_winter(2000) - 730475.31751) < 1e-5




when not defined(js):
    import strutils
    import readTestDataHelper

    suite "AstronomyAppendixCTestCase":
        setup:
            var data = readTestData("nimcalcalpkg/tests/dates5.csv")
            let corrections = readTestData("nimcalcalpkg/tests/dates5.errata.csv")
            for i in data.low..data.high:
                data[i][4] = corrections[i][1]


        test "testSolarLongitude":
            for row in data:
                # +0.5 takes into account that the value has to be
                # calculated at 12:00 UTC
                let rd = parseFloat(row[0])
#                echo "slr: ", row[1]
                let sl = parseFloat(row[1])
#                echo "slf: ", sl
#                echo "slc: ", solar_longitude(rd + 0.5)
                check abs(solar_longitude(rd + 0.5) - sl) < 1e-6


        test "testNextSolsticeEquinox":
            # I run some tests for Gregorian year 1995 about new Moon and
            # start of season against data from HM Observatory...and they
            # are ok
            for row in data:
                let rd = parseFloat(row[0])
                let nse = parseFloat(row[2])
                let t = [solar_longitude_after(SPRING, rd),
                     solar_longitude_after(SUMMER, rd),
                     solar_longitude_after(AUTUMN, rd),
                     solar_longitude_after(WINTER, rd)]
                check abs(min(t) - nse) < 1e-6

        test "testLunarLongitude":
            for row in data:
                let rd = parseFloat(row[0])
                let ll = parseFloat(row[3])
                check abs(lunar_longitude(rd) - ll) < 1e-6


        test "testNextNewMoon":
            for row in data:
                let rd = parseFloat(row[0])
                let nnm = parseFloat(row[4])
                check abs(new_moon_at_or_after(rd) - nnm) < 1e-6


        test "testDawnInParis":
            # as clarified by Prof. Reingold in CL it is:
            #    (dawn day paris 18d0)
            # note that d0 stands for double float precision and in
            # the Python routines we use mpf with 52 digits for dawn()
            let alpha = angle(18, 0, 0)

            for row in data:
                let rd = parseFloat(row[0])
                let dip = row[5]                
                if dip == "bogus":
                    var raised = false
                    try:
                        discard dawn(rd, PARIS, alpha)
                    except:
                        raised = true
                    check raised
                else:
                    let dipf = parseFloat(dip)
                    check abs(`mod`(dawn(rd, PARIS, alpha), 1.0) - dipf) < 1e-6


        test "testSunsetInJerusalem":
            for row in data:
                let rd = parseFloat(row[0])
                let sij = parseFloat(row[9])
                check abs(`mod`(sunset(rd, JERUSALEM), 1.0) - sij) < 1e-6



