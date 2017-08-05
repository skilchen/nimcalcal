import unittest
import nimcalcal
import math

suite "AstronomicalLunarCalendarsTestCase":
    test "testUniversalFromDynamical":
        # from Meeus Example 10.a, pag 78
        let date = gregorian_date(1977, FEBRUARY, 18)
        let time = time_from_clock(time_of_day(3, 37, 40))
        let td   = fixed_from_gregorian(date).float64 + time 
        let utc  = universal_from_dynamical(td)
        let clk  = clock_from_moment(utc)
        check hour(clk) == 3
        check minute(clk) == 36
        check iround(seconds(clk)) == 52

    test "testDynamicalFromUniversal":
        # from Meeus Example 10.a, pag 78 (well, inverse of)
        var date = gregorian_date(1977, FEBRUARY, 18)
        var time = time_from_clock(time_of_day(3, 36, 52))
        var utc  = fixed_from_gregorian(date).float64 + time 
        var td   = dynamical_from_universal(utc)
        var clk  = clock_from_moment(td)
        check hour(clk) == 3
        check minute(clk) == 37
        check iround(seconds(clk)) == 40
        # from Meeus Example 10.b, pag 79
        # I shoud get 7:42 but I get [7, 57, mpf('54.660540372133255')]
        # The equivalent CL
        #     (load "calendrica-3.0.cl")
        #     (in-package "CC3")
        #     (setq date (gregorian-date 333 february  6))
        #     (setq time (time-from-clock '(6 0 0)))
        #     (setq utc (+ (fixed-from-gregorian date) time))
        #     (setq td (dynamical-from-universal utc))
        #     (setq clk (clock-from-moment td))
        # gives (7 57 54.660540566742383817L0) on CLisp on PC
        # The reply from Prof Reingold and Dershowitz says:
        # From      Ed Reingold <reingold@emr.cs.iit.edu>
        # To        Enrico Spinielli <enrico.spinielli@googlemail.com>
        # Cc        nachumd@tau.ac.il
        # date      Thu, Aug 6, 2009 at 3:46 PM
        # subject   Re: dynamical-from-universal values differ from Meeus
        # mailed-by emr.cs.iit.edu
        # hide details Aug 6
        # Our value of the ephemeris correction closely matches the value
        # given on the NASA web site
        # http://eclipse.gsfc.nasa.gov/SEhelp/deltat2004.html for 333
        # (interpolating between the years 300 and 400), namely,
        # their value is 7027 seconds, while ours is 7075 seconds.
        # Meeus uses 6146 seconds, the difference amounts to about 14 minutes.
        # With Allegro Common Lisp, our functions
        #
        # (clock-from-moment (dynamical-from-universal
        #                      (+ (fixed-from-julian '(333 2 6)) 0.25L0)))
        #
        # give
        #
        #      (7 57 54.660540372133255d0)
        #
        # while CLisp on my PC gives
        #
        #      (7 57 54.660540566742383817L0)
        #
        # The difference in Delta-T explains Meeus's value of 7:42am.
        #
        # I then follow Calendrica Calculations (and NASA)
        date = gregorian_date(333, FEBRUARY, 6)
        time = time_from_clock(time_of_day(6, 0, 0))
        utc  = fixed_from_gregorian(date).float64 + time 
        td   = dynamical_from_universal(utc)
        clk  = clock_from_moment(td)
        check hour(clk) == 7
        check minute(clk) == 57
        check abs(seconds(clk) - 54.66054) < pow(1.0, -15.0)


    test "testNutation":
        # from Meeus, pag 343
        let epsilon = pow(1.0, -16.0)
        let TD  = fixed_from_gregorian(gregorian_date(1992, APRIL, 12))
        let tee = universal_from_dynamical(TD.float64)
        check abs(nutation(tee) - 0.004610) < epsilon

    test "testMeanLunarLongitude":
        # from Example 47.a in Jan Meeus "Astronomical Algorithms" pag 342
        check abs(mean_lunar_longitude(-0.077221081451) - 134.290182) < pow(1.0, -16.0)

    test "testLunarElongation":
        # from Example 47.a in Jan Meeus "Astronomical Algorithms" pag 342
        check abs(lunar_elongation(-0.077221081451) - 113.842304) <  pow(1.0, -16.0)

    test "testSolarAnomaly":
        # from Example 47.a in Jan Meeus "Astronomical Algorithms" pag 342
        check abs(solar_anomaly(-0.077221081451) - 97.643514) < pow(1.0, -16.0)


    test "testLunarAnomaly":
        # from Example 47.a in Jan Meeus "Astronomical Algorithms" pag 342
        check abs(lunar_anomaly(-0.077221081451) - 5.150833) < pow(1.0, -16.0)


    test "testMoonNode":
        # from Example 47.a in Jan Meeus "Astronomical Algorithms" pag 342
        check abs(moon_node(-0.077221081451) - 219.889721) < pow(1.0, -16.0)




