discard """Nim implementation of Dershowitz and Reingold 'Calendrica Calculations'.

Python implementation of calendrical algorithms as described in Common
Lisp in calendrical-3.0.cl (and errata as made available by the authors.)
The companion book is Dershowitz and Reingold 'Calendrica Calculations',
3rd Ed., 2008, Cambridge University Press.

License: MIT License for my work, but read the one
         for calendrica-3.0.cl which inspired this work.

Author: Enrico Spinielli

Translator to Nim: Samuel Kilchenmann


# Copyright (c) 2009 Enrico Spinielli
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# AUTOMATICALLY GENERATED FROM pycalcal.nw: ANY CHANGES WILL BE OVERWRITTEN.

"""

# use true division
#from __future__ import division

# Precision in bits, for places where CL postfixes numbers with L0, meaning
# at least 50 bits of precision
#from mpmath import *
#mp.prec = 50

import future
import math
import times
import tables
import sequtils

type 
    calDate* = object
        year*: int
        month*: int
        day*: int

    calTime = object
        hour: int
        minute: int
        second: float64

    calISODate = object
        year*: int
        week*: int
        day*: int

    calRomanDate = object
        year: int
        month: int
        event: int
        count: int
        leap: bool


proc `$`*(date: calDate): string = 
    result = ""
    var length = len($date.year)
    while length < 4:
        result.add(" ")
        inc(length)
    result.add($date.year)
    result.add("-")
    result.add(if date.month < 10: "0" else: "")
    result.add($date.month)
    result.add("-")
    result.add(if date.day < 10: "0" else: "")
    result.add($date.day)

proc `$`*(date: calISODate): string = 
    result = $date.year
    result.add("-")
    result.add(if date.week < 10: "0" else: "")
    result.add($date.week)
    result.add("-")
    result.add(if date.day < 10: "0" else: "")
    result.add($date.day)

proc `$`*(time: calTime): string =
    result = ""
    result.add(if time.hour < 10: "0" else: "") 
    result.add($time.hour)
    result.add(":")
    result.add(if time.minute < 10: "0" else: "")
    result.add($time.minute)
    result.add(":")
    result.add(if time.second < 10: "0" else: "")
    result.add($time.second)


proc mpf[T](x: T): float64 =
    return x.float64

#################################
## basic calendrical algorithms #
#################################
# see lines 244-247 in calendrica-3.0.cl
const BOGUS = "bogus"


# I (re)define floor: in CL it always returns an integer.
# I make it explicit the fact it returns an integer by
# naming it ifloor
proc ifloor*[T](n: T): int = 
    ## Return the whole part of m/n.
    # from math import floor
    return int(floor(n.float64))


# see lines 249-252 in calendrica-3.0.cl
# m // n
# The following
#      from operator import floordiv as quotient
# is not ok, the corresponding CL code
# uses CL 'floor' which always returns an integer
# (the floating point equivalent is 'ffloor'), while
# 'quotient' from operator module (or corresponding //)
# can return a float if at least one of the operands
# is a float...so I redefine it (and 'floor' and 'round' as well: in CL
# they always return an integer.)
proc quotient*[T](m, n:T): int = 
    ## Return the whole part of m/n towards negative infinity.
    return ifloor(m / n)


proc quotient*(m: int, n: float64): int = 
    ## Return the whole part of m/n towards negative infinity.
    return ifloor(m.float64 / n)

# proc modulo*[T](x: T, y: T): T =
#     return x.T - quotient(x.T, y).T * y

proc modulo*[B, T](x: B, y: T): T =
    return x.T - quotient(x.T, y.T).T * y

# I (re)define round: in CL it always returns an integer.
# I make it explicit the fact it returns an integer by
# naming it iround
proc iround*[T](n: T): int = 
    ## Return the whole part of m/n.
    return int(round(n))


# see lines 254-257 in calendrica-3.0.cl
proc amod*[T](x, y: T): int =
    ## Return the same as a % b with b instead of 0.
    return int(y.float64 + modulo(x.float64, -y.float64))


# see lines 259-264 in calendrica-3.0.cl
proc next*[T](i: T, p: proc(x: T): bool): T =
    ## Return first integer greater or equal to initial index, i,
    ## such that condition, p, holds.
    if p(i):
        return i 
    else:
        return(next(i + 1, p))


# see lines 266-271 in calendrica-3.0.cl
proc final*[T](i: T, p: proc(x: T): bool): T =
    ## Return last integer greater or equal to initial index, i,
    ## such that condition, p, holds.
    return if not p(i): i - 1  else: final(i + 1, p)


# see lines 273-281 in calendrica-3.0.cl
proc summa*[T](f: proc(x: T): T, k: int, p: proc(x: T): bool): T =
    ## Return the sum of f(i) from i=k, k+1, ... till p(i) holds true or 0.
    ## This is a tail recursive implementation.
    return if not p(k): 0 else: f(k) + summa(f, k + 1, p)


proc altsumma*[T](f: proc(x: T): T, k: int, p: proc(x: T): bool): T =
    ## Return the sum of f(i) from i=k, k+1, ... till p(i) holds true or 0.
    ## This is an implementation of the Summation formula from Kahan,
    ## see Theorem 8 in Goldberg, David 'What Every Computer Scientist
    ## Should Know About Floating-Point Arithmetic', ACM Computer Survey,
    ## Vol. 23, No. 1, March 1991.
     
    var S: T
    if not p(k):
        return 0
    else:
        S = f(k)
        var C = 0
        var j = k + 1
        while p(j):
            let Y = f(j) - C
            T = S + Y
            C = (T - S) - Y
            S = T
            j += 1
    return S


# see lines 283-293 in calendrica-3.0.cl
proc binary_search*[T](lo, hi: T, p: proc(x, y: T): bool, e: proc(x: T): bool): T =
    ## Bisection search for x in [lo, hi] such that condition 'e' holds.
    ## p determines when to go left.
    let x = (lo + hi) / 2
    if p(lo, hi):
        return x
    elif e(x):
        return binary_search(lo, x, p, e)
    else:
        return binary_search(x, hi, p, e)


# see lines 295-302 in calendrica-3.0.cl
proc invert_angular*(f: proc(x: float64): float64, 
                    y, a, b: float64, prec: float64 = 1.0 / 100_000): float64 = 
    ## Find inverse of angular function 'f' at 'y' within interval [a,b].
    ## Default precision is 0.00001
    return binary_search(a, b,
                         (proc(lo, hi: float64): bool = ((hi - lo) <= prec)),
                         (proc(x: float64): bool = modulo((f(x) - y), 360.0) < 180.0))


proc myzip[T](seqs: varargs[seq[T]]): seq[seq[T]] =
    var minLen = high(int)
    for i in items(seqs):
        if i.len < minLen:
            minLen = i.len
    newSeq(result, minLen)

    for i in 0..<minLen:
        var oneSeq = newSeq[T](seqs.len)
        for j, s in pairs(seqs):
            oneSeq[j] = s[i]
        result[i] = oneSeq


# see lines 304-313 in calendrica-3.0.cl
proc sigma*[T](seqOfSeqs: seq[seq[T]], b: proc(x: seq[T]): T): T =
    ## Return the sum of body 'b' for indices i1..in
    ## running simultaneously thru lists l1..ln.
    ## List 'l' is of the form [[i1 l1]..[in ln]]
    
    # 'l' is a list of 'n' lists of the same lenght 'L' [l1, l2, l3, ...]
    # 'b' is a lambda with 'n' args
    # 'sigma' sums all 'L' applications of 'b' to the relevant tuple of args
    # >>> a = [ 1, 2, 3, 4]
    # >>> b = [ 5, 6, 7, 8]
    # >>> c = [ 9,10,11,12]
    # >>> l = [a,b,c]
    # >>> z = zip(*l)
    # >>> z
    # [(1, 5, 9), (2, 6, 10), (3, 7, 11), (4, 8, 12)]
    # >>> b = lambda x, y, z: x * y * z
    # >>> b(*z[0]) # apply b to first elem of i
    # 45
    # >>> temp = []
    # >>> z = zip(*l)
    # >>> for e in z: temp.append(b(*e))
    # >>> temp
    # [45, 120, 231, 384]
    # >>> from operator import add
    # >>> reduce(add, temp)
    # 780

    #let r = lc[b(x) | (x <- myzip(seqOfSeqs)), T]
    #let r = future.lc[x | (x <- 1..5, x>1), int]
    var sum = 0.T
    for x in myzip(seqOfSeqs):
        sum += b(x)
    return sum


# see lines 315-321 in calendrica-3.0.cl
proc poly*(x: float64, a: openArray[float64]): float64 = 
    ## Calculate polynomial with coefficients 'a' at point x.
    ## The polynomial is a[0] + a[1] * x + a[2] * x^2 + ...a[n-1]x^(n-1)
    ## the result is
    ## a[0] + x(a[1] + x(a[2] +...+ x(a[n-1])...)
    ## This implementation is also known as Horner's Rule.
    let n = a.high
    var p = a[n]
    for i in 1..n:
        p = p * x + a[n-i]
    return p


# see lines 323-329 in calendrica-3.0.cl
# Epoch definition. I took it out explicitly from rd().
proc epoch*(): untyped = 
    ## Epoch definition. For Rata Diem, R.D., it is 0 (but any other reference
    ## would do.)
    return 0


proc rd*[T](tee: T): T =
    ## Return rata diem (number of days since epoch) of moment in time, tee.
    return tee - epoch()


# see lines 331-334 in calendrica-3.0.cl
const SUNDAY = 0

# see lines 10-15 in calendrica-3.0.errata.cl
const MONDAY = 1

# see lines 17-20 in calendrica-3.0.errata.cl
const TUESDAY = 2

# see lines 22-25 in calendrica-3.0.errata.cl
const WEDNESDAY = 3

# see lines 27-30 in calendrica-3.0.errata.cl
const THURSDAY = 4

# see lines 32-35 in calendrica-3.0.errata.cl
const FRIDAY = 5

# see lines 37-40 in calendrica-3.0.errata.cl
const SATURDAY = SUNDAY + 6

# const tables do not work with the nodejs backend
let DAYS_OF_WEEK_NAMES* = {
    SUNDAY    : "Sunday",
    MONDAY    : "Monday",
    TUESDAY   : "Tuesday",
    WEDNESDAY : "Wednesday",
    THURSDAY  : "Thursday",
    FRIDAY    : "Friday",
    SATURDAY  : "Saturday"
}.toTable


# see lines 366-369 in calendrica-3.0.cl
proc day_of_week_from_fixed*(date: int): int =
    ## Return day of the week from a fixed date 'date'.
    return modulo(date - rd(0) - SUNDAY, 7)

# see lines 371-374 in calendrica-3.0.cl
proc standard_month*(date: calDate): int = 
    ## Return the month of date 'date'.
    return date.month


# see lines 376-379 in calendrica-3.0.cl
proc standard_day*(date: calDate): int =
    ## Return the day of date 'date'.
    return date.day


# see lines 381-384 in calendrica-3.0.cl
proc standard_year*(date: calDate): int =
    ## Return the year of date 'date'.
    return date.year


# see lines 386-388 in calendrica-3.0.cl
proc time_of_day*(hour, minute: int, second: float64): calTime = 
    ## Return the time of day data structure
    return calTime(hour: hour, minute: minute, second: second)


# see lines 390-392 in calendrica-3.0.cl
proc hour*(clock: calTime): int =
    ## Return the hour of clock time 'clock'.
    return clock.hour


# see lines 394-396 in calendrica-3.0.cl
proc minute*(clock: calTime): int = 
    ## Return the minutes of clock time 'clock'.
    return clock.minute


# see lines 398-400 in calendrica-3.0.cl
proc seconds*(clock: calTime): float64 =
    ## Return the seconds of clock time 'clock'.
    return clock.second


# see lines 402-405 in calendrica-3.0.cl
proc fixed_from_moment*[T](tee: T): int =
    ## Return fixed date from moment 'tee'.
    return ifloor(tee)


# see lines 407-410 in calendrica-3.0.cl
proc time_from_moment*[T](tee: T): float64 = 
    ## Return time from moment 'tee'.
    return modulo(tee, 1.0)


# see lines 412-419 in calendrica-3.0.cl
proc clock_from_moment*[T](tee: T): calTime = 
    ## Return clock time hour:minute:second from moment 'tee'.
    let time = time_from_moment(tee)
    var hour = ifloor(time * 24)
    var minute = ifloor(modulo(time * 24 * 60, 60).float64)
    let second = modulo(time * 24 * 60 * 60, 60.0).float64
    #var isecond = iround(second)
    var  isecond = second
    if isecond == 60:
        minute += 1
        isecond = 0
        if minute == 60:
            hour += 1
            minute = 0
    return time_of_day(hour, minute, isecond.float64)


# see lines 421-427 in calendrica-3.0.cl
proc time_from_clock*(hms: calTime): float64 = 
    ## Return time of day from clock time 'hms'.
    let h = hour(hms).float64
    let m = minute(hms).float64
    let s = seconds(hms).float64
    return(1/24 * (h + ((m + (s / 60)) / 60)))


# see lines 429-431 in calendrica-3.0.cl
proc degrees_minutes_seconds*[T](d, m, s: T): tuple = 
    ## Return the angular data structure.
    return [d, m, s]


# see lines 433-440 in calendrica-3.0.cl
proc angle_from_degrees*[T](alpha:T): tuple = 
    ## Return an angle in degrees:minutes:seconds from angle,
    ## 'alpha' in degrees.
    
    let d = ifloor(alpha)
    let m = ifloor(60 * modulo(alpha, 1))
    let s = modulo(alpha * 60 * 60, 60)
    return degrees_minutes_seconds(d, m, s)


# see lines 487-490 in calendrica-3.0.cl
proc start(range: tuple): int =
    ## Return the start of range 'range'.
    return range[0]


# see lines 492-495 in calendrica-3.0.cl
proc endr(range: tuple): int = 
    ## Return the end of range 'range'.
    return range[1]


# see lines 497-500 in calendrica-3.0.cl
proc is_in_range[T](tee: T, range: tuple): bool =
    ## Return True if moment 'tee' falls within range 'range',
    ## False otherwise.
    if start(range) <= tee and tee <= endr(range):
        return true
    else:
        return false


# see lines 502-510 in calendrica-3.0.cl
proc list_range[T](ell: openArray[T], range: tuple): seq[T] =
    ## Return those moments in list ell that occur in range 'range'.
    result = @[]
    for i in ell:
        if is_in_range(i, range):
            result.add(i)
    return result


# see lines 482-485 in calendrica-3.0.cl
proc interval[T](t0, t1: T): (T, T) = 
    ## Return the range data structure.
    return (t0, t1)


# see lines 442-445 in calendrica-3.0.cl
const JD_EPOCH = rd(-1721424.5.float64)


# see lines 447-450 in calendrica-3.0.cl
proc moment_from_jd*[T](jd: T): float64 =
    ## Return the moment corresponding to the Julian day number 'jd'.
    return jd.float64 + JD_EPOCH


# see lines 452-455 in calendrica-3.0.cl
proc jd_from_moment*[T](tee: T): T =
    ## Return the Julian day number corresponding to moment 'tee'.
    return tee - JD_EPOCH


# see lines 457-460 in calendrica-3.0.cl
proc fixed_from_jd*[T](jd: T): int =
    ## Return the fixed date corresponding to Julian day number 'jd'.
    return ifloor(moment_from_jd(jd))


# see lines 462-465 in calendrica-3.0.cl
proc jd_from_fixed*[T](date: T): T = 
    ## Return the Julian day number corresponding to fixed date 'rd'.
    return jd_from_moment(date)


# see lines 467-470 in calendrica-3.0.cl
const MJD_EPOCH = rd(678576)


# see lines 472-475 in calendrica-3.0.cl
proc fixed_from_mjd*[T](mjd: T): T =
    ## Return the fixed date corresponding to modified Julian day 'mjd'.
    return mjd + MJD_EPOCH


# see lines 477-480 in calendrica-3.0.cl
proc mjd_from_fixed*[T](date: T): T =
    ## Return the modified Julian day corresponding to fixed date 'rd'.
    return date - MJD_EPOCH


###############################################
## egyptian and armenian calendars algorithms #
###############################################
# see lines 515-518 in calendrica-3.0.cl
proc egyptian_date*(year, month, day: int): calDate =
    ## Return the Egyptian date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 520-525 in calendrica-3.0.cl
const EGYPTIAN_EPOCH = fixed_from_jd(1448638)


# see lines 527-536 in calendrica-3.0.cl
proc fixed_from_egyptian*(e_date: calDate): int =
    ## Return the fixed date corresponding to Egyptian date 'e_date'.
    let month = standard_month(e_date)
    let day   = standard_day(e_date)
    let year  = standard_year(e_date)
    return EGYPTIAN_EPOCH + (365*(year - 1)) + (30*(month - 1)) + (day - 1)


# see lines 538-553 in calendrica-3.0.cl
proc egyptian_from_fixed*(date: int): calDate =
    ## Return the Egyptian date corresponding to fixed date 'date'.
    let days = date - EGYPTIAN_EPOCH
    let year = 1 + quotient(days, 365)
    let month = 1 + quotient(modulo(days, 365), 30)
    let day = days - (365*(year - 1)) - (30*(month - 1)) + 1
    return egyptian_date(year, month, day)


# see lines 555-558 in calendrica-3.0.cl
proc armenian_date*(year, month, day: int): calDate =
    ## Return the Armenian date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 560-564 in calendrica-3.0.cl
const ARMENIAN_EPOCH = rd(201443)


# see lines 566-575 in calendrica-3.0.cl
proc fixed_from_armenian*(a_date: calDate): int = 
    ## Return the fixed date corresponding to Armenian date 'a_date'.
    let month = standard_month(a_date)
    let day   = standard_day(a_date)
    let year  = standard_year(a_date)
    return (ARMENIAN_EPOCH +
            fixed_from_egyptian(egyptian_date(year, month, day)) -
            EGYPTIAN_EPOCH)


# see lines 577-581 in calendrica-3.0.cl
proc armenian_from_fixed*(date: int): calDate =
    ## Return the Armenian date corresponding to fixed date 'date'.
    return egyptian_from_fixed(date + (EGYPTIAN_EPOCH - ARMENIAN_EPOCH))


##################################
## gregorian calendar algorithms #
##################################
# see lines 586-589 in calendrica-3.0.cl
proc gregorian_date*(year, month, day: int): calDate =
    ## Return a Gregorian date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 591-595 in calendrica-3.0.cl 
const GREGORIAN_EPOCH = rd(1)

# see lines 597-600 in calendrica-3.0.cl
const JANUARY* = 1

# see lines 602-605 in calendrica-3.0.cl
const FEBRUARY* = 2

# see lines 607-610 in calendrica-3.0.cl
const MARCH* = 3

# see lines 612-615 in calendrica-3.0.cl
const APRIL* = 4

# see lines 617-620 in calendrica-3.0.cl
const MAY* = 5

# see lines 622-625 in calendrica-3.0.cl
const JUNE* = 6

# see lines 627-630 in calendrica-3.0.cl
const JULY* = 7

# see lines 632-635 in calendrica-3.0.cl
const AUGUST* = 8

# see lines 637-640 in calendrica-3.0.cl
const SEPTEMBER* = 9

# see lines 642-645 in calendrica-3.0.cl
const OCTOBER* = 10

# see lines 647-650 in calendrica-3.0.cl
const NOVEMBER* = 11

# see lines 652-655 in calendrica-3.0.cl
const DECEMBER* = 12


# see lines 657-663 in calendrica-3.0.cl
proc is_gregorian_leap_year*(g_year: int): bool = 
    ## Return True if Gregorian year 'g_year' is leap.
    return (modulo(g_year, 4) == 0) and (modulo(g_year, 400) notin {100, 200, 300})


# see lines 665-687 in calendrica-3.0.cl
proc fixed_from_gregorian*(g_date: calDate): int =
    ## Return the fixed date equivalent to the Gregorian date 'g_date'.
    let month = standard_month(g_date)
    let day   = standard_day(g_date)
    let year  = standard_year(g_date)
    result = GREGORIAN_EPOCH - 1
    result += (365 * (year - 1))
    result += quotient(year - 1, 4)
    result -= quotient(year - 1, 100) 
    result += quotient(year - 1, 400)
    result += quotient((367 * month) - 362, 12)
    if month <= 2: 
        result += 0 
    else: 
        if is_gregorian_leap_year(year): 
            result -= 1 
        else:
            result -= 2
    result += day

const UNIX_EPOCH = fixed_from_gregorian(gregorian_date(1970, 1, 1))

proc fixed_from_now*(): int =
    let ti = getGMTime(fromSeconds(epochTime()))
    return fixed_from_gregorian(gregorian_date(ti.year, ord(ti.month) + 1, ti.monthday))

proc moment_from_now*(): float64 =
    let ti = getGMTime(fromSeconds(epochTime()))
    let fixed = fixed_from_gregorian(
                  gregorian_date(ti.year, ord(ti.month) + 1, ti.monthday))
    let td = time_of_day(ti.hour, ti.minute, ti.second.float64)
    return fixed.float64 + time_from_clock(td)

proc epoch_seconds_from_moment(moment: float64): float64 =
    return (moment - UNIX_EPOCH.float64) * 24 * 60 * 60 

proc lunar_phase*(tee: float64): float64 {.gcsafe.}
proc gregorian_from_fixed*(date: int): calDate {.gcsafe.}


# see lines 689-715 in calendrica-3.0.cl
proc gregorian_year_from_fixed*(date: int): int =
    ## Return the Gregorian year corresponding to the fixed date 'date'.
    let d0   = date - GREGORIAN_EPOCH
    #echo "d0: ", d0
    let n400 = quotient(d0, 146097)
    #echo "n400: ", n400
    let d1   = modulo(d0, 146097)
    #echo "d1: ", d1
    let n100 = quotient(d1, 36524)
    #echo "n100: ", n100
    let d2   = modulo(d1, 36524)
    #echo "d2: ", d2
    let n4   = quotient(d2, 1461)
    #echo "n4: ", n4
    let d3   = modulo(d2, 1461)
    #echo "d3: ", d3
    let n1   = quotient(d3, 365)
    #echo "n1: ", n1
    let year = (400 * n400) + (100 * n100) + (4 * n4) + n1
    #echo "year: ", year
    if n100 == 4 or n1 == 4:
        return year
    else:
        return year + 1


# see lines 717-721 in calendrica-3.0.cl
proc gregorian_new_year*(g_year: int): int = 
    ## Return the fixed date of January 1 in Gregorian year 'g_year'.
    return fixed_from_gregorian(gregorian_date(g_year, JANUARY, 1))


# see lines 723-727 in calendrica-3.0.cl
proc gregorian_year_end*(g_year: int): int =
    ## Return the fixed date of December 31 in Gregorian year 'g_year'.
    return fixed_from_gregorian(gregorian_date(g_year, DECEMBER, 31))


# see lines 729-733 in calendrica-3.0.cl
proc gregorian_year_range*(g_year: int): (int, int) = 
    ## Return the range of fixed dates in Gregorian year 'g_year'.
    return interval(gregorian_new_year(g_year), gregorian_year_end(g_year))


# see lines 735-756 in calendrica-3.0.cl
proc gregorian_from_fixed*(date: int): calDate =
    ## Return the Gregorian date corresponding to fixed date 'date'.
    let year = gregorian_year_from_fixed(date)
    let prior_days = date - gregorian_new_year(year)
    var correction: int 
    if (date < fixed_from_gregorian(gregorian_date(year, MARCH, 1))): 
        correction = 0
    else:
        if is_gregorian_leap_year(year):
            correction = 1
        else:
            correction = 2
    let month = quotient((12 * (prior_days + correction)) + 373, 367)
    let day = 1 + (date - fixed_from_gregorian(gregorian_date(year, month, 1)))
    return gregorian_date(year, month, day)


# see lines 758-763 in calendrica-3.0.cl
proc gregorian_date_difference*(g_date1, g_date2: calDate): int = 
    ## Return the number of days from Gregorian date 'g_date1'
    ## till Gregorian date 'g_date2'.
    return fixed_from_gregorian(g_date2) - fixed_from_gregorian(g_date1)


# see lines 42-49 in calendrica-3.0.errata.cl
proc day_number*(g_date: calDate): int = 
    ## Return the day number in the year of Gregorian date 'g_date'.
    return gregorian_date_difference(
        gregorian_date(standard_year(g_date) - 1, DECEMBER, 31),
        g_date)


# see lines 53-58 in calendrica-3.0.cl
proc days_remaining*(g_date: calDate): int =
    ## Return the days remaining in the year after Gregorian date 'g_date'.
    return gregorian_date_difference(
        g_date,
        gregorian_date(standard_year(g_date), DECEMBER, 31))


# see lines 779-801 in calendrica-3.0.cl
proc alt_fixed_from_gregorian*(g_date: calDate): int =
    ## Return the fixed date equivalent to the Gregorian date 'g_date'.
    ## Alternative calculation.
    let month = standard_month(g_date)
    let day   = standard_day(g_date)
    let year  = standard_year(g_date)
    let m     = amod(month - 2, 12)
    let y     = year + quotient(month + 9, 12)
    return ((GREGORIAN_EPOCH - 1)  +
            -306                   +
            365 * (y - 1)          +
            quotient(y - 1, 4)     +
            -quotient(y - 1, 100)  +
            quotient(y - 1, 400)   +
            quotient(3 * m - 1, 5) +
            30 * (m - 1)           +
            day)


# see lines 803-825 in calendrica-3.0.cl
proc alt_gregorian_from_fixed*(date: int): calDate =
    ## Return the Gregorian date corresponding to fixed date 'date'.
    ## Alternative calculation.
    let y = gregorian_year_from_fixed(GREGORIAN_EPOCH - 1 + date + 306)
    let prior_days = date - fixed_from_gregorian(gregorian_date(y - 1, MARCH, 1))
    let month = amod(quotient(5 * prior_days + 2, 153) + 3, 12)
    let year  = y - quotient(month + 9, 12)
    let day   = date - fixed_from_gregorian(gregorian_date(year, month, 1)) + 1
    return gregorian_date(year, month, day)


# see lines 827-841 in calendrica-3.0.cl
proc alt_gregorian_year_from_fixed*(date: int): int =
    ## Return the Gregorian year corresponding to the fixed date 'date'.
    ## Alternative calculation.
    let approx = quotient(date - GREGORIAN_EPOCH + 2, 146097 / 400)
    let start  = (GREGORIAN_EPOCH       +
                 (365 * approx)         +
                 quotient(approx, 4)    +
                 -quotient(approx, 100) +
                 quotient(approx, 400))
    return if (date < start): approx  else: (approx + 1)


# see lines 843-847 in calendrica-3.0.cl
proc independence_day*(g_year: int ): int =
    ## Return the fixed date of United States Independence Day in
    ## Gregorian year 'g_year'.
    return fixed_from_gregorian(gregorian_date(g_year, JULY, 4))


# see lines 849-853 in calendrica-3.0.cl
proc kday_on_or_before*(k, date: int): int =
    ## Return the fixed date of the k-day on or before fixed date 'date'.
    ## k=0 means Sunday, k=1 means Monday, and so on.
    return date - day_of_week_from_fixed(date - k)


# see lines 855-859 in calendrica-3.0.cl
proc kday_on_or_after*(k, date: int): int =
    ## Return the fixed date of the k-day on or after fixed date 'date'.
    ## k=0 means Sunday, k=1 means Monday, and so on.
    return kday_on_or_before(k, date + 6)


# see lines 861-865 in calendrica-3.0.cl
proc kday_nearest*(k, date: int): int =
    ## Return the fixed date of the k-day nearest fixed date 'date'.
    ## k=0 means Sunday, k=1 means Monday, and so on.
    return kday_on_or_before(k, date + 3)


# see lines 867-871 in calendrica-3.0.cl
proc kday_after*(k, date: int): int =
    ## Return the fixed date of the k-day after fixed date 'date'.
    ## k=0 means Sunday, k=1 means Monday, and so on.
    return kday_on_or_before(k, date + 7)


# see lines 873-877 in calendrica-3.0.cl
proc kday_before*(k, date: int): int =
    ## Return the fixed date of the k-day before fixed date 'date'.
    ## k=0 means Sunday, k=1 means Monday, and so on.
    return kday_on_or_before(k, date - 1)


# see lines 62-74 in calendrica-3.0.errata.cl
proc nth_kday*(n, k: int, g_date: calDate): int|string =
    ## Return the fixed date of n-th k-day after Gregorian date 'g_date'.
    ## If n>0, return the n-th k-day on or after  'g_date'.
    ## If n<0, return the n-th k-day on or before 'g_date'.
    ## If n=0, return BOGUS.
    ## A k-day of 0 means Sunday, 1 means Monday, and so on.
    if n > 0:
        return 7*n + kday_before(k, fixed_from_gregorian(g_date))
    elif n < 0:
        return 7*n + kday_after(k, fixed_from_gregorian(g_date))
    else:
        raise newException(ValueError, BOGUS)


# see lines 892-897 in calendrica-3.0.cl
proc first_kday*(k: int, g_date: calDate): int|string =
    ## Return the fixed date of first k-day on or after Gregorian date 'g_date'.
    ## A k-day of 0 means Sunday, 1 means Monday, and so on.
    return nth_kday(1, k, g_date)


# see lines 899-904 in calendrica-3.0.cl
proc last_kday*(k: int, g_date: calDate): int|string = 
    ## Return the fixed date of last k-day on or before Gregorian date 'g_date'.
    ## A k-day of 0 means Sunday, 1 means Monday, and so on.
    return nth_kday(-1, k, g_date)


# see lines 906-910 in calendrica-3.0.cl
proc labor_day*(g_year: calDate): int|string =
    ## Return the fixed date of United States Labor Day in Gregorian
    ## year 'g_year' (the first Monday in September).
    return first_kday(MONDAY, gregorian_date(g_year, SEPTEMBER, 1))


# see lines 912-916 in calendrica-3.0.cl
proc memorial_day*(g_year: int): int|string =
    ## Return the fixed date of United States' Memorial Day in Gregorian
    ## year 'g_year' (the last Monday in May).
    return last_kday(MONDAY, gregorian_date(g_year, MAY, 31))


# see lines 918-923 in calendrica-3.0.cl
proc election_day*(g_year: int): int|string =
    ## Return the fixed date of United States' Election Day in Gregorian
    ## year 'g_year' (the Tuesday after the first Monday in November).
    return first_kday(TUESDAY, gregorian_date(g_year, NOVEMBER, 2))


# see lines 925-930 in calendrica-3.0.cl
proc daylight_saving_start*(g_year: int): int|string = 
    ## Return the fixed date of the start of United States daylight
    ## saving time in Gregorian year 'g_year' (the second Sunday in March).
    return nth_kday(2, SUNDAY, gregorian_date(g_year, MARCH, 1))


# see lines 932-937 in calendrica-3.0.cl
proc daylight_saving_end*(g_year: int): int|string =
    ## Return the fixed date of the end of United States daylight saving
    ## time in Gregorian year 'g_year' (the first Sunday in November).
    return first_kday(SUNDAY, gregorian_date(g_year, NOVEMBER, 1))


# see lines 939-943 in calendrica-3.0.cl
proc christmas*(g_year: int): int|string =
    ## Return the fixed date of Christmas in Gregorian year 'g_year'.
    return fixed_from_gregorian(gregorian_date(g_year, DECEMBER, 25))


# see lines 945-951 in calendrica-3.0.cl
proc advent*(g_year: int): int|string =
    ## Return the fixed date of Advent in Gregorian year 'g_year'
    ## (the Sunday closest to November 30).
    return kday_nearest(SUNDAY,
                        fixed_from_gregorian(gregorian_date(g_year,
                                                            NOVEMBER,
                                                            30)))


# see lines 953-957 in calendrica-3.0.cl
proc epiphany*(g_year: int): int|string =
    ## Return the fixed date of Epiphany in U.S. in Gregorian year 'g_year'
    ## (the first Sunday after January 1).
    return first_kday(SUNDAY, gregorian_date(g_year, JANUARY, 2))


proc epiphany_it*(g_year: int): int|string =
    ## Return fixed date of Epiphany in Italy in Gregorian year 'g_year'.
    return gregorian_date(g_year, JANUARY, 6)


# see lines 959-974 in calendrica-3.0.cl
proc unlucky_fridays_in_range*(range: tuple): seq[int] =
    ## Return the list of Fridays within range 'range' of fixed dates that
    ## are day 13 of the relevant Gregorian months.
    result = @[]
    let a    = start(range)
    let b    = endr(range)
    let fri  = kday_on_or_after(FRIDAY, a)
    let date = gregorian_from_fixed(fri)
    if (standard_day(date) == 13): 
        result.add(fri)
    if is_in_range(fri, range):
        result.add(unlucky_fridays_in_range(interval(fri + 1, b)))


###############################
## julian calendar algorithms #
###############################
# see lines 1037-1040 in calendrica-3.0.cl
proc julian_date*(year, month, day: int): calDate =
    ## Return the Julian date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 1042-1045 in calendrica-3.0.cl
const JULIAN_EPOCH = fixed_from_gregorian(gregorian_date(0, DECEMBER, 30))


# see lines 1047-1050 in calendrica-3.0.cl
proc bce*(n: int): int =
    ## Retrun a negative value to indicate a BCE Julian year.
    return -n


# see lines 1052-1055 in calendrica-3.0.cl
proc ce*(n: int): int =
    ## Return a positive value to indicate a CE Julian year.
    return n


# see lines 1057-1060 in calendrica-3.0.cl
proc is_julian_leap_year*(j_year: int): bool = 
    ## Return True if Julian year 'j_year' is a leap year in
    ## the Julian calendar.
    return modulo(j_year, 4) == (if j_year > 0: 0 else: 3)


# see lines 1062-1082 in calendrica-3.0.cl
proc fixed_from_julian*(j_date: calDate): int = 
    ## Return the fixed date equivalent to the Julian date 'j_date'.
    let month = standard_month(j_date)
    let day   = standard_day(j_date)
    let year  = standard_year(j_date)
    let y     = if year < 0: year + 1 else: year
    return (JULIAN_EPOCH - 1 +
            (365 * (y - 1)) +
            quotient(y - 1, 4) +
            quotient(367*month - 362, 12) +
            (if month <= 2: 0 else: (if is_julian_leap_year(year): -1 else: -2)) +
            day)


# see lines 1084-1111 in calendrica-3.0.cl
proc julian_from_fixed*(date: int): calDate =
    ## Return the Julian date corresponding to fixed date 'date'.
    let approx     = quotient(((4 * (date - JULIAN_EPOCH))) + 1464, 1461)
    let year       = if approx <= 0: approx - 1 else: approx
    let prior_days = date - fixed_from_julian(julian_date(year, JANUARY, 1))
    let correction = (if date < fixed_from_julian(julian_date(year, MARCH, 1)): 0 else:
                     (if is_julian_leap_year(year): 1 else: 2))
    let month      = quotient(12*(prior_days + correction) + 373, 367)
    let day        = 1 + (date - fixed_from_julian(julian_date(year, month, 1)))
    return julian_date(year, month, day)


# see lines 1113-1116 in calendrica-3.0.cl
const KALENDS = 1

# see lines 1118-1121 in calendrica-3.0.cl
const NONES = 2

# see lines 1123-1126 in calendrica-3.0.cl
const IDES = 3


# see lines 1128-1131 in calendrica-3.0.cl
proc roman_date*(year, month, event, count: int, leap: bool): calRomanDate =
    ## Return the Roman date data structure.
    return calRomanDate(year: year, 
                        month: month, 
                        event: event, 
                        count: count, 
                        leap: leap)


# see lines 1133-1135 in calendrica-3.0.cl
proc roman_year*(date: calRomanDate): int =
    ## Return the year of Roman date 'date'.
    return date.year


# see lines 1137-1139 in calendrica-3.0.cl
proc roman_month*(date: calRomanDate): int =
    ## Return the month of Roman date 'date'.
    return date.month


# see lines 1141-1143 in calendrica-3.0.cl
proc roman_event*(date: calRomanDate): int =
    ## Return the event of Roman date 'date'.
    return date.event


# see lines 1145-1147 in calendrica-3.0.cl
proc roman_count*(date: calRomanDate): int =
    ## Return the count of Roman date 'date'.
    return date.count


# see lines 1149-1151 in calendrica-3.0.cl
proc roman_leap*(date: calRomanDate): bool =
    ## Return the leap indicator of Roman date 'date'.
    return date.leap


# see lines 1153-1158 in calendrica-3.0.cl
proc ides_of_month*(month: int): int =
    ## Return the date of the Ides in Roman month 'month'.
    return if month in [MARCH, MAY, JULY, OCTOBER]: 15 else: 13


# see lines 1160-1163 in calendrica-3.0.cl
proc nones_of_month*(month: int): int =
    ## Return the date of Nones in Roman month 'month'.
    return ides_of_month(month) - 8


# see lines 1165-1191 in calendrica-3.0.cl
proc fixed_from_roman*(r_date: calRomanDate): int =
    ## Return the fixed date corresponding to Roman date 'r_date'.
    let leap  = roman_leap(r_date)
    let count = roman_count(r_date)
    let event = roman_event(r_date)
    let month = roman_month(r_date)
    let year  = roman_year(r_date)
    var s1 = 0
    case event
        of KALENDS: s1 = fixed_from_julian(julian_date(year, month, 1)) 
        of NONES: s1 =  fixed_from_julian(julian_date(year,
                                                    month,
                                                    nones_of_month(month)))
        of IDES: s1 = fixed_from_julian(julian_date(year,
                                                    month,
                                                    ides_of_month(month)))
        else:
            discard

    s1 -= count

    if not (is_julian_leap_year(year) and
            (month == MARCH) and
            (event == KALENDS) and
            (count >= 6 and count <= 16)): 
        s1 += 1

    if leap:
        s1 += 1 

    return s1


# see lines 1193-1229 in calendrica-3.0.cl   
proc roman_from_fixed*(date: int): calRomanDate =
    ## Return the Roman name corresponding to fixed date 'date'.
    
    let j_date = julian_from_fixed(date)
    let month  = standard_month(j_date)
    let day    = standard_day(j_date)
    let year   = standard_year(j_date)
    let month_prime = amod(1 + month, 12)
    var year_prime  = 0
    if month_prime != 1: 
        year_prime = year  
    else: 
        if year != -1: 
            year_prime = year + 1 
        else: 
            year_prime = 1

    let kalends1 = fixed_from_roman(
        roman_date(year_prime, month_prime, KALENDS, 1, false))

    if day == 1:
        result = roman_date(year, month, KALENDS, 1, false)
    elif day <= nones_of_month(month):
        result = roman_date(year,
                            month,
                            NONES, 
                            nones_of_month(month) - day + 1,
                            false)
    elif day <= ides_of_month(month):
        result = roman_date(year,
                            month,
                            IDES,
                            ides_of_month(month) - day + 1,
                            false)
    elif (month != FEBRUARY) or not is_julian_leap_year(year):
        result = roman_date(year_prime,
                            month_prime,
                            KALENDS,
                            kalends1 - date + 1,
                            false)
    elif day < 25:
        result = roman_date(year, MARCH, KALENDS, 30 - day, false)
    else:
        result = roman_date(year, MARCH, KALENDS, 31 - day, day == 25)
    return result


# see lines 1231-1234 in calendrica-3.0.cl
const YEAR_ROME_FOUNDED = bce(753)


# see lines 1236-1241 in calendrica-3.0.cl
proc julian_year_from_auc_year*(year: int): int =
    ## Return the Julian year equivalent to AUC year 'year'.
    
    if year >= 1 and year <= (year - YEAR_ROME_FOUNDED):
        result = year + YEAR_ROME_FOUNDED - 1
    else:
        result = year + YEAR_ROME_FOUNDED
    return result


# see lines 1243-1248 in calendrica-3.0.cl
proc auc_year_from_julian_year*(year: int): int =
    ## Return the AUC year equivalent to Julian year 'year'.
    
    if (year >= YEAR_ROME_FOUNDED and year <= -1):
        result = (year - YEAR_ROME_FOUNDED - 1)
    else:
        result = year - YEAR_ROME_FOUNDED
    return result


# see lines 1250-1266 in calendrica-3.0.cl
proc julian_in_gregorian*(j_month, j_day, g_year: int): seq[int] =
    ## Return the list of the fixed dates of Julian month 'j_month', day
    ## 'j_day' that occur in Gregorian year 'g_year'.
    let jan1 = gregorian_new_year(g_year)
    let y    = standard_year(julian_from_fixed(jan1))
    let y_prime = if (y == -1): 1 else: (y + 1)
    let date1 = fixed_from_julian(julian_date(y, j_month, j_day))
    let date2 = fixed_from_julian(julian_date(y_prime, j_month, j_day))
    return list_range([date1, date2], gregorian_year_range(g_year))
    

# see lines 1268-1272 in calendrica-3.0.cl
proc eastern_orthodox_christmas*(g_year: int): seq[int] =
    ## Return the list of zero or one fixed dates of Eastern Orthodox Christmas
    ## in Gregorian year 'g_year'.
    return julian_in_gregorian(DECEMBER, 25, g_year)


############################
## ISO calendar algorithms #
############################
# see lines 979-981 in calendrica-3.0.cl
proc iso_date*(year, week, day: int): calISODate =
    ## Return the ISO date data structure.
    return calISODate(year: year, week: week, day: day)


# see lines 983-985 in calendrica-3.0.cl
proc iso_week*(date: calISODate): int =
    ## Return the week of ISO date 'date'
    return date.week


# see lines 987-989 in calendrica-3.0.cl
proc iso_day*(date: calISODate): int = 
    ## Return the day of ISO date 'date'.
    return date.day


# see lines 991-993 in calendrica-3.0.cl
proc iso_year*(date: calISODate): int = 
    ## Return the year of ISO date 'date'.
    return date.year


# see lines 995-1005 in calendrica-3.0.cl
proc fixed_from_iso*(i_date: calISODate): int =
    ## Return the fixed date equivalent to ISO date 'i_date'.
    let week = iso_week(i_date)
    let day  = iso_day(i_date)
    let year = iso_year(i_date)
    return nth_kday(week, SUNDAY, gregorian_date(year - 1, DECEMBER, 28)) + day


# see lines 1007-1022 in calendrica-3.0.cl
proc iso_from_fixed*(date: int): calISODate = 
    ## Return the ISO date corresponding to the fixed date 'date'.
    var approx = gregorian_year_from_fixed(date - 3)
    var year = approx 
    if date >= fixed_from_iso(iso_date(approx + 1, 1, 1)):
        year += 1
    let week   = 1 + quotient(date - fixed_from_iso(iso_date(year, 1, 1)), 7)
    let day    = amod(date - rd(0), 7)
    return iso_date(year, week, day)


# see lines 1024-1032 in calendrica-3.0.cl
proc is_iso_long_year*(i_year: int): bool = 
    ## Return True if ISO year 'i_year' is a long (53-week) year.
    let jan1  = day_of_week_from_fixed(gregorian_new_year(i_year))
    let dec31 = day_of_week_from_fixed(gregorian_year_end(i_year))
    return (jan1 == THURSDAY) or (dec31 == THURSDAY)

proc dates_in_iso_week(year, iso_week_nr: int): seq[int] =
    result = @[]
    var first = fixed_from_iso(iso_date(year, iso_week_nr, 1))
    result.add(first)
    for i in 1..6:
        result.add(first + i)

# see lines 1277-1279 in calendrica-3.0.cl
#############################################
## coptic and ethiopic calendars algorithms #
#############################################
proc coptic_date*(year, month, day: int): calDate =
    ## Return the Coptic date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 1281-1284 in calendrica-3.0.cl
const COPTIC_EPOCH = fixed_from_julian(julian_date(ce(284), AUGUST, 29))


# see lines 1286-1289 in calendrica-3.0.cl
proc is_coptic_leap_year*(c_year: int): bool =
    ## Return True if Coptic year 'c_year' is a leap year
    ## in the Coptic calendar.
    return modulo(c_year, 4) == 3


# see lines 1291-1301 in calendrica-3.0.cl
proc fixed_from_coptic*(c_date: calDate): int = 
    ## Return the fixed date of Coptic date 'c_date'.
    let month = standard_month(c_date)
    let day   = standard_day(c_date)
    let year  = standard_year(c_date)
    return (COPTIC_EPOCH - 1  +
            365 * (year - 1)  +
            quotient(year, 4) +
            30 * (month - 1)  +
            day)


# see lines 1303-1318 in calendrica-3.0.cl
proc coptic_from_fixed*(date: int ): calDate =
    ## Return the Coptic date equivalent of fixed date 'date'.
    let year  = quotient((4 * (date - COPTIC_EPOCH)) + 1463, 1461)
    let month = 1 + quotient(date - fixed_from_coptic(coptic_date(year, 1, 1)), 30)
    let day   = date + 1 - fixed_from_coptic(coptic_date(year, month, 1))
    return coptic_date(year, month, day)


# see lines 1320-1323 in calendrica-3.0.cl
proc ethiopic_date*(year, month, day: int): calDate =
    ## Return the Ethiopic date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 1325-1328 in calendrica-3.0.cl
const ETHIOPIC_EPOCH = fixed_from_julian(julian_date(ce(8), AUGUST, 29))

# see lines 1330-1339 in calendrica-3.0.cl
proc fixed_from_ethiopic*(e_date: calDate): int =
    ## Return the fixed date corresponding to Ethiopic date 'e_date'.
    let month = standard_month(e_date)
    let day   = standard_day(e_date)
    let year  = standard_year(e_date)
    return (ETHIOPIC_EPOCH +
            fixed_from_coptic(coptic_date(year, month, day)) - COPTIC_EPOCH)


# see lines 1341-1345 in calendrica-3.0.cl
proc ethiopic_from_fixed*(date: int): calDate =
    ## Return the Ethiopic date equivalent of fixed date 'date'.
    return coptic_from_fixed(date + (COPTIC_EPOCH - ETHIOPIC_EPOCH))


# see lines 1347-1360 in calendrica-3.0.cl
proc coptic_in_gregorian*(c_month, c_day, g_year: int): seq[int] =
    ## Return the list of the fixed dates of Coptic month 'c_month',
    ## day 'c_day' that occur in Gregorian year 'g_year'.
    let jan1  = gregorian_new_year(g_year)
    let y     = standard_year(coptic_from_fixed(jan1))
    let date1 = fixed_from_coptic(coptic_date(y, c_month, c_day))
    let date2 = fixed_from_coptic(coptic_date(y+1, c_month, c_day))
    return list_range([date1, date2], gregorian_year_range(g_year))


# see lines 1362-1366 in calendrica-3.0.cl
proc coptic_christmas*(g_year: int): seq[int] =
    ## Return the list of zero or one fixed dates of Coptic Christmas
    ## dates in Gregorian year 'g_year'.
    return coptic_in_gregorian(4, 29, g_year)


########################################
## ecclesiastical calendars algorithms #
########################################
# see lines 1371-1385 in calendrica-3.0.cl
proc orthodox_easter*(g_year: int): int =
    ## Return fixed date of Orthodox Easter in Gregorian year g_year.
    
    let shifted_epact = modulo(14 + 11 * modulo(g_year, 19), 30)
    let j_year        = if g_year > 0: g_year else: g_year - 1
    let paschal_moon  = fixed_from_julian(
                            julian_date(j_year, APRIL, 19)) - shifted_epact
    return kday_after(SUNDAY, paschal_moon)


# see lines 76-91 in calendrica-3.0.errata.cl
proc alt_orthodox_easter*(g_year: int ): int =
    ## Return fixed date of Orthodox Easter in Gregorian year g_year.
    ## Alternative calculation.
    
    let paschal_moon = (354 * g_year +
                        30 * quotient((7 * g_year) + 8, 19) +
                        quotient(g_year, 4)  -
                        quotient(g_year, 19) -
                        273 +
                        GREGORIAN_EPOCH)

    return kday_after(SUNDAY, paschal_moon)


# see lines 1401-1426 in calendrica-3.0.cl
proc easter*(g_year: int): int =
    ## Return fixed date of Easter in Gregorian year g_year.
    let century = quotient(g_year, 100) + 1
    let shifted_epact = modulo(14 + (11 * modulo(g_year, 19)) -
                              quotient(3 * century, 4) +
                              quotient(5 + (8 * century), 25), 30)
    var adjusted_epact = shifted_epact
    if (shifted_epact == 0) or (shifted_epact == 1 and
                                (10 < modulo(g_year, 19))):
        adjusted_epact = shifted_epact + 1
    else:
        adjusted_epact = shifted_epact
    let paschal_moon = (fixed_from_gregorian(gregorian_date(g_year, APRIL, 19)) -
                       adjusted_epact)
    return kday_after(SUNDAY, paschal_moon)


# see lines 1429-1431 in calendrica-3.0.cl
proc pentecost*(g_year: int): int =
    ## Return fixed date of Pentecost in Gregorian year g_year.
    return easter(g_year) + 49


################################
## islamic calendar algorithms #
################################
# see lines 1436-1439 in calendrica-3.0.cl
proc islamic_date*(year, month, day: int): calDate =
    ## Return an Islamic date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 1441-1444 in calendrica-3.0.cl
const ISLAMIC_EPOCH = fixed_from_julian(julian_date(ce(622), JULY, 16))


# see lines 1446-1449 in calendrica-3.0.cl
proc is_islamic_leap_year*(i_year: int): bool = 
    ## Return True if i_year is an Islamic leap year.
    return modulo(14 + 11 * i_year, 30) < 11


# see lines 1451-1463 in calendrica-3.0.cl
proc fixed_from_islamic*(i_date: calDate): int =
    ## Return fixed date equivalent to Islamic date i_date.
    let month = standard_month(i_date)
    let day   = standard_day(i_date)
    let year  = standard_year(i_date)
    return (ISLAMIC_EPOCH - 1 +
            (year - 1) * 354  +
            quotient(3 + 11 * year, 30) +
            29 * (month - 1) +
            quotient(month, 2) +
            day)


# see lines 1465-1483 in calendrica-3.0.cl
proc islamic_from_fixed*(date: int): calDate =
    ## Return Islamic date (year month day) corresponding to fixed date date.
    let year       = quotient(30 * (date - ISLAMIC_EPOCH) + 10646, 10631)
    let prior_days = date - fixed_from_islamic(islamic_date(year, 1, 1))
    let month      = quotient(11 * prior_days + 330, 325)
    let day        = date - fixed_from_islamic(islamic_date(year, month, 1)) + 1
    return islamic_date(year, month, day)


# see lines 1485-1501 in calendrica-3.0.cl
proc islamic_in_gregorian*(i_month, i_day, g_year: int): seq[int] =
    ## Return list of the fixed dates of Islamic month i_month, day i_day that
    ## occur in Gregorian year g_year.
    let jan1  = gregorian_new_year(g_year)
    let y     = standard_year(islamic_from_fixed(jan1))
    let date1 = fixed_from_islamic(islamic_date(y, i_month, i_day))
    let date2 = fixed_from_islamic(islamic_date(y + 1, i_month, i_day))
    let date3 = fixed_from_islamic(islamic_date(y + 2, i_month, i_day))
    return list_range([date1, date2, date3], gregorian_year_range(g_year))


# see lines 1503-1507 in calendrica-3.0.cl
proc mawlid_an_nabi*(g_year: int): seq[int] =
    ## Return list of fixed dates of Mawlid_an_Nabi occurring in Gregorian
    ## year g_year.
    return islamic_in_gregorian(3, 12, g_year)


###############################
## hebrew calendar algorithms #
###############################
# see lines 1512-1514 in calendrica-3.0.cl
proc hebrew_date*(year, month, day: int): calDate =
    ## Return an Hebrew date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 1516-1519 in calendrica-3.0.cl
const NISAN = 1

# see lines 1521-1524 in calendrica-3.0.cl
const IYYAR = 2

# see lines 1526-1529 in calendrica-3.0.cl
const SIVAN = 3

# see lines 1531-1534 in calendrica-3.0.cl
const TAMMUZ = 4

# see lines 1536-1539 in calendrica-3.0.cl
const AV = 5

# see lines 1541-1544 in calendrica-3.0.cl
const ELUL = 6

# see lines 1546-1549 in calendrica-3.0.cl
const TISHRI = 7

# see lines 1551-1554 in calendrica-3.0.cl
const MARHESHVAN = 8

# see lines 1556-1559 in calendrica-3.0.cl
const KISLEV = 9

# see lines 1561-1564 in calendrica-3.0.cl
const TEVET = 10

# see lines 1566-1569 in calendrica-3.0.cl
const SHEVAT = 11

# see lines 1571-1574 in calendrica-3.0.cl
const ADAR = 12

# see lines 1576-1579 in calendrica-3.0.cl
const ADARII = 13

# const tables do not work with the nodejs backend
let HEBREW_MONTH_NAMES = {
    NISAN      : "Nisan",
    IYYAR      : "Iyyar",
    SIVAN      : "Sivan",
    TAMMUZ     : "Tammuz",
    AV         : "Av",
    ELUL       : "Elul",
    TISHRI     : "Tishri",
    MARHESHVAN : "Marheshvan",
    KISLEV     : "Kislev",
    TEVET      : "Tevet",
    SHEVAT     : "Shevat",
    ADAR       : "Adar",
    ADARII     : "Adar I"
}.toTable()


# see lines 1581-1585 in calendrica-3.0.cl
const HEBREW_EPOCH = fixed_from_julian(julian_date(bce(3761),  OCTOBER, 7))


# see lines 1587-1590 in calendrica-3.0.cl
proc is_hebrew_leap_year*(h_year: int): bool =
    ## Return True if h_year is a leap year on Hebrew calendar.
    return modulo(7 * h_year + 1, 19) < 7


# see lines 1592-1597 in calendrica-3.0.cl
proc last_month_of_hebrew_year*(h_year: int): int =
    ## Return last month of Hebrew year.
    return if is_hebrew_leap_year(h_year): ADARII else: ADAR


# see lines 1599-1603 in calendrica-3.0.cl
proc is_hebrew_sabbatical_year*(h_year: int): bool = 
    ## Return True if h_year is a sabbatical year on the Hebrew calendar.
    return modulo(h_year, 7) == 0


# see lines 1636-1663 in calendrica-3.0.cl
proc hebrew_calendar_elapsed_days*(h_year: int ): int =
    ## Return number of days elapsed from the (Sunday) noon prior
    ## to the epoch of the Hebrew calendar to the mean
    ## conjunction (molad) of Tishri of Hebrew year h_year,
    ## or one day later.
    let months_elapsed = quotient(235 * h_year - 234, 19)
    let parts_elapsed  = 12084 + 13753 * months_elapsed
    let days = 29 * months_elapsed + quotient(parts_elapsed, 25920)
    return  if (modulo(3 * (days + 1), 7) < 3): (days + 1) else: days


# see lines 1672-1684 in calendrica-3.0.cl
proc hebrew_year_length_correction*(h_year: int): int =
    ## Return delays to start of Hebrew year h_year to keep ordinary
    ## year in range 353-356 and leap year in range 383-386.
    # I had a bug... h_year = 1 instead of h_year - 1!!!
    let ny0 = hebrew_calendar_elapsed_days(h_year - 1)
    let ny1 = hebrew_calendar_elapsed_days(h_year)
    let ny2 = hebrew_calendar_elapsed_days(h_year + 1)
    if ((ny2 - ny1) == 356):
        return 2
    elif ((ny1 - ny0) == 382):
        return 1
    else:
        return 0


# see lines 1665-1670 in calendrica-3.0.cl
proc hebrew_new_year*(h_year: int): int =
    ## Return fixed date of Hebrew new year h_year.
    return (HEBREW_EPOCH +
           hebrew_calendar_elapsed_days(h_year) +
           hebrew_year_length_correction(h_year))


# see lines 1686-1690 in calendrica-3.0.cl
proc days_in_hebrew_year*(h_year: int): int =
    ## Return number of days in Hebrew year h_year.
    return hebrew_new_year(h_year + 1) - hebrew_new_year(h_year)

# see lines 1692-1695 in calendrica-3.0.cl
proc is_long_marheshvan*(h_year: int): bool =
    ## Return True if Marheshvan is long in Hebrew year h_year.
    return days_in_hebrew_year(h_year) in [355, 385]


# see lines 1697-1700 in calendrica-3.0.cl
proc is_short_kislev*(h_year: int): bool =
    ## Return True if Kislev is short in Hebrew year h_year.
    return days_in_hebrew_year(h_year) in [353, 383]


# see lines 1605-1617 in calendrica-3.0.cl
proc last_day_of_hebrew_month*(h_month, h_year: int): int =
    ## Return last day of month h_month in Hebrew year h_year.
    if ((h_month in {IYYAR, TAMMUZ, ELUL, TEVET, ADARII}) or
       ((h_month == ADAR) and (not is_hebrew_leap_year(h_year))) or
       ((h_month == MARHESHVAN) and (not is_long_marheshvan(h_year))) or
       ((h_month == KISLEV) and is_short_kislev(h_year))):
        return 29
    else:
        return 30

proc days_from_hours*(x: int|float64): float64 {.gcsafe.}

# see lines 1619-1634 in calendrica-3.0.cl
proc molad*(h_month, h_year: int): float64 =
    ## Return moment of mean conjunction of h_month in Hebrew h_year.
    let y = if (h_month < TISHRI): (h_year + 1) else: h_year
    let months_elapsed = h_month - TISHRI + quotient(235 * y - 234, 19)
    return (HEBREW_EPOCH.float64 -
           (876.float64 / 25920.float64).float64 +
           months_elapsed.float64 * (29 + days_from_hours(12) + (793/25920).float64))


# see lines 1702-1721 in calendrica-3.0.cl
proc fixed_from_hebrew*(h_date: calDate): int = 
    ## Return fixed date of Hebrew date h_date.
    let month = standard_month(h_date)
    let day   = standard_day(h_date)
    let year  = standard_year(h_date)

    var tmp: int 
    if (month < TISHRI):
        tmp = (summa(proc(m: int):int = last_day_of_hebrew_month(m, year),
                     TISHRI,
                     proc(m: int):bool = m <= last_month_of_hebrew_year(year)) +
               summa(proc(m: int): int = last_day_of_hebrew_month(m, year),
                     NISAN,
                     proc(m: int):bool = m < month))
    else:
        tmp = summa(proc(m: int):int = last_day_of_hebrew_month(m, year),
                    TISHRI,
                    proc(m: int):bool = m < month)

    return hebrew_new_year(year) + day - 1 + tmp


# see lines 1723-1751 in calendrica-3.0.cl
proc hebrew_from_fixed*(date: int): calDate =
    ## Return  Hebrew (year month day) corresponding to fixed date date.
    ## The fraction can be approximated by 365.25.
    let approx = quotient(date - HEBREW_EPOCH, 35975351/98496) + 1
    let year = final(approx - 1, proc(y:int):bool = hebrew_new_year(y) <= date)
    var start: int
    if (date < fixed_from_hebrew(hebrew_date(year, NISAN, 1))):
        start = TISHRI
    else:
        start = NISAN
    let month = next(start, proc(m: int):bool = date <= fixed_from_hebrew(
        hebrew_date(year, m, last_day_of_hebrew_month(m, year))))
    let day = date - fixed_from_hebrew(hebrew_date(year, month, 1)) + 1
    return hebrew_date(year, month, day)


# see lines 1753-1761 in calendrica-3.0.cl
proc yom_kippur*(g_year: int): int =
    ## Return fixed date of Yom Kippur occurring in Gregorian year g_year.
    let hebrew_year = g_year - gregorian_year_from_fixed(HEBREW_EPOCH) + 1
    return fixed_from_hebrew(hebrew_date(hebrew_year, TISHRI, 10))


# see lines 1763-1770 in calendrica-3.0.cl
proc passover*(g_year: int): int =
    ## Return fixed date of Passover occurring in Gregorian year g_year.
    let hebrew_year = g_year - gregorian_year_from_fixed(HEBREW_EPOCH)
    return fixed_from_hebrew(hebrew_date(hebrew_year, NISAN, 15))


# see lines 1772-1782 in calendrica-3.0.cl
proc omer*(date: int): (int, int) =
    ## Return the number of elapsed weeks and days in the omer at date date.
    ## Returns BOGUS if that date does not fall during the omer.
    let c = date - passover(gregorian_year_from_fixed(date))
    if (c >= 1 and c <= 49): 
        return (quotient(c, 7), modulo(c, 7)) 
    else: 
        raise newException(ValueError, BOGUS)


# see lines 1784-1793 in calendrica-3.0.cl
proc purim*(g_year: int): int =
    ## Return fixed date of Purim occurring in Gregorian year g_year.
    let hebrew_year = g_year - gregorian_year_from_fixed(HEBREW_EPOCH)
    let last_month  = last_month_of_hebrew_year(hebrew_year)
    return fixed_from_hebrew(hebrew_date(hebrew_year, last_month, 14))


# see lines 1795-1805 in calendrica-3.0.cl
proc ta_anit_esther*(g_year: int): int =
    ## Return fixed date of Ta'anit Esther occurring in Gregorian
    ## year g_year.
    let purim_date = purim(g_year)
    if (day_of_week_from_fixed(purim_date) == SUNDAY):
        return purim_date - 3
    else:
        return purim_date - 1


# see lines 1807-1821 in calendrica-3.0.cl
proc tishah_be_av*(g_year: int): int =
    ## Return fixed date of Tishah be_Av occurring in Gregorian year g_year.
    let hebrew_year = g_year - gregorian_year_from_fixed(HEBREW_EPOCH)
    let av9 = fixed_from_hebrew(hebrew_date(hebrew_year, AV, 9))
    if (day_of_week_from_fixed(av9) == SATURDAY):
        return av9 + 1  
    else:
        return av9


# see lines 1823-1834 in calendrica-3.0.cl
proc birkath_ha_hama*(g_year: int): seq[int] =
    ## Return the list of fixed date of Birkath ha_Hama occurring in
    ## Gregorian year g_year, if it occurs.
    let dates = coptic_in_gregorian(7, 30, g_year)
    if dates.len > 0 and
       modulo(standard_year(coptic_from_fixed(dates[0])), 28) == 17:
        return dates
    else:
        return @[]


# see lines 1836-1840 in calendrica-3.0.cl
proc sh_ela*(g_year: int): seq[int] =
    ## Return the list of fixed dates of Sh'ela occurring in
    ## Gregorian year g_year.
    return coptic_in_gregorian(3, 26, g_year)


# exercise for the reader from pag 104
proc hebrew_in_gregorian*(h_month, h_day, g_year: int): seq[int] =
    ## Return list of the fixed dates of Hebrew month, h_month, day, h_day,
    ## that occur in Gregorian year g_year.
    let jan1  = gregorian_new_year(g_year)
    let y     = standard_year(hebrew_from_fixed(jan1))
    let date1 = fixed_from_hebrew(hebrew_date(y, h_month, h_day))
    let date2 = fixed_from_hebrew(hebrew_date(y + 1, h_month, h_day))
    # Hebrew and Gregorian calendar are aligned but certain
    # holidays, i.e. Tzom Tevet, can fall on either side of Jan 1.
    # So we can have 0, 1 or 2 occurences of that holiday.
    let dates = @[date1, date2]
    return list_range(dates, gregorian_year_range(g_year))


# see pag 104
proc tzom_tevet*(g_year: int): seq[int] =
    ## Return the list of fixed dates for Tzom Tevet (Tevet 10) that
    ## occur in Gregorian year g_year. It can occur 0, 1 or 2 times per
    ## Gregorian year.
    let jan1  = gregorian_new_year(g_year)
    let y     = standard_year(hebrew_from_fixed(jan1))
    var d1 = fixed_from_hebrew(hebrew_date(y, TEVET, 10))
    d1 = if (day_of_week_from_fixed(d1) == SATURDAY): (d1 + 1) else: d1
    var d2 = fixed_from_hebrew(hebrew_date(y + 1, TEVET, 10))
    d2 = if (day_of_week_from_fixed(d2) == SATURDAY): (d2 + 1) else: d2
    let dates = @[d1, d2]
    return list_range(dates, gregorian_year_range(g_year))


# this is a simplified version where no check for SATURDAY
# is performed: from hebrew year 1 till 2000000
# there is no TEVET 10 falling on Saturday...
proc alt_tzom_tevet*(g_year: int): seq[int] =
    ## Return the list of fixed dates for Tzom Tevet (Tevet 10) that
    ## occur in Gregorian year g_year. It can occur 0, 1 or 2 times per
    ## Gregorian year.
    return hebrew_in_gregorian(TEVET, 10, g_year)


# see lines 1842-1859 in calendrica-3.0.cl
proc yom_ha_zikkaron*(g_year: int): int = 
    ## Return fixed date of Yom ha_Zikkaron occurring in Gregorian
    ## year g_year.
    let hebrew_year = g_year - gregorian_year_from_fixed(HEBREW_EPOCH)
    let iyyar4 = fixed_from_hebrew(hebrew_date(hebrew_year, IYYAR, 4))
    
    if day_of_week_from_fixed(iyyar4) in [THURSDAY, FRIDAY]:
        return kday_before(WEDNESDAY, iyyar4)
    elif SUNDAY == day_of_week_from_fixed(iyyar4):
        return iyyar4 + 1
    else:
        return iyyar4


# see lines 1861-1879 in calendrica-3.0.cl
proc hebrew_birthday*(birthdate: calDate, h_year: int): int =
    ## Return fixed date of the anniversary of Hebrew birth date
    ## birthdate occurring in Hebrew h_year.
    let birth_day   = standard_day(birthdate)
    let birth_month = standard_month(birthdate)
    let birth_year  = standard_year(birthdate)
    if birth_month == last_month_of_hebrew_year(birth_year):
        return fixed_from_hebrew(hebrew_date(h_year,
                                             last_month_of_hebrew_year(h_year),
                                             birth_day))
    else:
        return (fixed_from_hebrew(hebrew_date(h_year, birth_month, 1)) +
                birth_day - 1)


# see lines 1881-1893 in calendrica-3.0.cl
proc hebrew_birthday_in_gregorian*(birthdate: calDate, g_year: int): seq[int] =
    ## Return the list of the fixed dates of Hebrew birthday
    ## birthday that occur in Gregorian g_year.
    let jan1 = gregorian_new_year(g_year)
    let y    = standard_year(hebrew_from_fixed(jan1))
    let date1 = hebrew_birthday(birthdate, y)
    let date2 = hebrew_birthday(birthdate, y + 1)
    return list_range([date1, date2], gregorian_year_range(g_year))


# see lines 1895-1937 in calendrica-3.0.cl
proc yahrzeit*(death_date: calDate, h_year: int): int =
    ## Return fixed date of the anniversary of Hebrew death date death_date
    ## occurring in Hebrew h_year.
    let death_day   = standard_day(death_date)
    let death_month = standard_month(death_date)
    let death_year  = standard_year(death_date)

    if death_month == MARHESHVAN and
        death_day == 30 and
        not is_long_marheshvan(death_year + 1):
        return fixed_from_hebrew(hebrew_date(h_year, KISLEV, 1)) - 1
    elif death_month == KISLEV and
          death_day == 30 and
          is_short_kislev(death_year + 1):
        return fixed_from_hebrew(hebrew_date(h_year, TEVET, 1)) - 1
    elif death_month == ADARII:
        return fixed_from_hebrew(hebrew_date(h_year,
                                             last_month_of_hebrew_year(h_year),
                                             death_day))
    elif death_day == 30 and
          death_month == ADAR and
          not is_hebrew_leap_year(h_year):
        return fixed_from_hebrew(hebrew_date(h_year, SHEVAT, 30))
    else:
        return fixed_from_hebrew(hebrew_date(h_year, death_month, 1)) +
                death_day - 1


# see lines 1939-1951 in calendrica-3.0.cl
proc yahrzeit_in_gregorian*(death_date: calDate, g_year: int): seq[int] =
    ## Return the list of the fixed dates of death date death_date (yahrzeit)
    ## that occur in Gregorian year g_year.
    let jan1 = gregorian_new_year(g_year)
    let y    = standard_year(hebrew_from_fixed(jan1))
    let date1 = yahrzeit(death_date, y)
    let date2 = yahrzeit(death_date, y + 1)
    return list_range([date1, date2], gregorian_year_range(g_year))


# see lines 1953-1960 in calendrica-3.0.cl
proc shift_days*(lst: seq[int], cap_Delta: int): seq[int] =
    ## Shift each weekday on list l by cap_Delta days.
    result = @[]
    for x in lst:
        result.add(day_of_week_from_fixed(x) + cap_Delta)
    return result


# see lines 480-504 in calendrica-3.0.errata.cl
proc possible_hebrew_days*(h_month: int, h_day: int): seq[int] =
    ## Return a list of possible days of week for Hebrew day h_day
    ## and Hebrew month h_month.
    let h_date0 = hebrew_date(5, NISAN, 1)
    let h_year  = if (h_month > ELUL): 6 else: 5
    let h_date  = hebrew_date(h_year, h_month, h_day)
    let n       = fixed_from_hebrew(h_date) - fixed_from_hebrew(h_date0)
    let basic   = @[TUESDAY, THURSDAY, SATURDAY]

    var extra: seq[int] = @[]
    if h_month == MARHESHVAN and h_day == 30:
        extra = @[]
    elif h_month == KISLEV and h_day < 30:
        extra = @[MONDAY, WEDNESDAY, FRIDAY]
    elif h_month == KISLEV and h_day == 30:
        extra = @[MONDAY]
    elif h_month in [TEVET, SHEVAT]:
        extra = @[SUNDAY, MONDAY]
    elif h_month == ADAR and h_day < 30:
        extra = @[SUNDAY, MONDAY]
    else:
        extra = @[SUNDAY]

    return shift_days(basic & extra, n)


###############################
## mayan calendars algorithms #
###############################
# see lines 1989-1992 in calendrica-3.0.cl
type calMayanLongCountDate = object
    baktun: int
    katun: int
    tun: int
    uinal: int
    kin: int

proc mayan_long_count_date*(baktun, katun, tun, uinal, kin: int): calMayanLongCountDate =
    ## Return a long count Mayan date data structure. 
    return calMayanLongCountDate(baktun: baktun, 
                              katun: katun, 
                              tun: tun, 
                              uinal: uinal,
                              kin: kin)

type calMayanHaabDate = object
    month: int
    day: int

# see lines 1994-1996 in calendrica-3.0.cl
proc mayan_haab_date*(month, day: int): calMayanHaabDate =
    ## Return a Haab Mayan date data structure.
    return calMayanHaabDate(month: month, day: day)


type calMayanTzolkinDate = object
    number: int
    name: int

# see lines 1998-2001 in calendrica-3.0.cl
proc mayan_tzolkin_date*(number, name: int): calMayanTzolkinDate =
    ## Return a Tzolkin Mayan date data structure.
    return calMayanTzolkinDate(number: number, name: name)


# see lines 2003-2005 in calendrica-3.0.cl
proc mayan_baktun*(date: calMayanLongCountDate): int =
    ## Return the baktun field of a long count Mayan
    ## date = [baktun, katun, tun, uinal, kin].
    return date.baktun


# see lines 2007-2009 in calendrica-3.0.cl
proc mayan_katun*(date: calMayanLongCountDate): int =
    ## Return the katun field of a long count Mayan
    ## date = [baktun, katun, tun, uinal, kin].
    return date.katun


# see lines 2011-2013 in calendrica-3.0.cl
proc mayan_tun*(date: calMayanLongCountDate): int =
    ## Return the tun field of a long count Mayan
    ## date = [baktun, katun, tun, uinal, kin].
    return date.tun


# see lines 2015-2017 in calendrica-3.0.cl
proc mayan_uinal(date: calMayanLongCountDate): int =
    ## Return the uinal field of a long count Mayan
    ## date = [baktun, katun, tun, uinal, kin].
    return date.uinal


# see lines 2019-2021 in calendrica-3.0.cl
proc mayan_kin*(date: calMayanLongCountDate): int =
    ## Return the kin field of a long count Mayan
    ## date = [baktun, katun, tun, uinal, kin].
    return date.kin


# see lines 2023-2025 in calendrica-3.0.cl
proc mayan_haab_month*(date: calMayanHaabDate): int =
    ## Return the month field of Haab Mayan date = [month, day].
    return date.month


# see lines 2027-2029 in calendrica-3.0.cl
proc mayan_haab_day*(date: calMayanHaabDate): int =
    ## Return the day field of Haab Mayan date = [month, day].
    return date.day


# see lines 2031-2033 in calendrica-3.0.cl
proc mayan_tzolkin_number*(date: calMayanTzolkinDate): int = 
    ## Return the number field of Tzolkin Mayan date = [number, name].
    return date.number


# see lines 2035-2037 in calendrica-3.0.cl
proc mayan_tzolkin_name*(date: calMayanTzolkinDate): int =
    ## Return the name field of Tzolkin Mayan date = [number, name].
    return date.name


# see lines 2039-2044 in calendrica-3.0.cl
const MAYAN_EPOCH = fixed_from_jd(584283)


# see lines 2046-2060 in calendrica-3.0.cl
proc fixed_from_mayan_long_count*(count: calMayanLongCountDate): int =
    ## Return fixed date corresponding to the Mayan long count count,
    ## which is a list [baktun, katun, tun, uinal, kin].
    let baktun = mayan_baktun(count)
    let katun  = mayan_katun(count)
    let tun    = mayan_tun(count)
    let uinal  = mayan_uinal(count)
    let kin    = mayan_kin(count)
    return (MAYAN_EPOCH       +
            (baktun * 144000) +
            (katun * 7200)    +
            (tun * 360)       +
            (uinal * 20)      +
            kin)


proc divmod*(x, y: int): (int, int) =
    result[0] = x div y
    result[1] = x mod y

# see lines 2062-2074 in calendrica-3.0.cl
proc mayan_long_count_from_fixed*(date: int): calMayanLongCountDate =
    ## Return Mayan long count date of fixed date date.
    let long_count = date - MAYAN_EPOCH
    let (baktun, day_of_baktun)  = divmod(long_count, 144000)
    let (katun, day_of_katun)    = divmod(day_of_baktun, 7200)
    let (tun, day_of_tun)        = divmod(day_of_katun, 360)
    let (uinal, kin)             = divmod(day_of_tun, 20)
    return mayan_long_count_date(baktun, katun, tun, uinal, kin)

# see lines 2076-2081 in calendrica-3.0.cl
proc mayan_haab_ordinal*(h_date: calMayanHaabDate): int =
    ## Return the number of days into cycle of Mayan haab date h_date.
    let day   = mayan_haab_day(h_date)
    let month = mayan_haab_month(h_date)
    return ((month - 1) * 20) + day


# see lines 2083-2087 in calendrica-3.0.cl
const MAYAN_HAAB_EPOCH = MAYAN_EPOCH - mayan_haab_ordinal(mayan_haab_date(18, 8))


# see lines 2089-2096 in calendrica-3.0.cl
proc mayan_haab_from_fixed*(date: int): calMayanHaabDate =
    ## Return Mayan haab date of fixed date date.
    let count = modulo(date - MAYAN_HAAB_EPOCH, 365)
    let day   = modulo(count, 20)
    let month = quotient(count, 20) + 1
    return mayan_haab_date(month, day)


# see lines 2098-2105 in calendrica-3.0.cl
proc mayan_haab_on_or_before*(haab: calMayanHaabDate, date: int): int =
    ## Return fixed date of latest date on or before fixed date date
    ## that is Mayan haab date haab.
    return date - modulo(date - MAYAN_HAAB_EPOCH - mayan_haab_ordinal(haab), 365)


# see lines 2107-2114 in calendrica-3.0.cl
proc mayan_tzolkin_ordinal*(t_date: calMayanTzolkinDate): int =
    ## Return number of days into Mayan tzolkin cycle of t_date.
    let number = mayan_tzolkin_number(t_date)
    let name   = mayan_tzolkin_name(t_date)
    return modulo(number - 1 + (39 * (number - name)), 260)


# see lines 2116-2120 in calendrica-3.0.cl
const MAYAN_TZOLKIN_EPOCH = (MAYAN_EPOCH - 
                             mayan_tzolkin_ordinal(mayan_tzolkin_date(4, 20)))


# see lines 2122-2128 in calendrica-3.0.cl
proc mayan_tzolkin_from_fixed*(date: int): calMayanTzolkinDate =
    ## Return Mayan tzolkin date of fixed date date.
    let count  = date - MAYAN_TZOLKIN_EPOCH + 1
    let number = amod(count, 13)
    let name   = amod(count, 20)
    return mayan_tzolkin_date(number, name)


# see lines 2130-2138 in calendrica-3.0.cl
proc mayan_tzolkin_on_or_before*(tzolkin: calMayanTzolkinDate, date: int): int =
    ## Return fixed date of latest date on or before fixed date date
    ## that is Mayan tzolkin date tzolkin.
    return (date -
            modulo(date -
                MAYAN_TZOLKIN_EPOCH -
                mayan_tzolkin_ordinal(tzolkin), 260))

# see lines 2140-2150 in calendrica-3.0.cl
proc mayan_year_bearer_from_fixed*(date: int): int =
    ## Return year bearer of year containing fixed date date.
    ## Returns BOGUS for uayeb.
    let x = mayan_haab_on_or_before(mayan_haab_date(1, 0), date + 364)
    if mayan_haab_month(mayan_haab_from_fixed(date)) == 19:
        raise newException(ValueError, BOGUS)
    else:
        return mayan_tzolkin_name(mayan_tzolkin_from_fixed(x))


# see lines 2152-2168 in calendrica-3.0.cl
proc mayan_calendar_round_on_or_before*(haab: calMayanHaabDate, 
                                       tzolkin: calMayanTzolkinDate,
                                       date: int): int =
    ## Return fixed date of latest date on or before date, that is
    ## Mayan haab date haab and tzolkin date tzolkin.
    ## Returns BOGUS for impossible combinations.
    let haab_count = mayan_haab_ordinal(haab) + MAYAN_HAAB_EPOCH
    let tzolkin_count = mayan_tzolkin_ordinal(tzolkin) + MAYAN_TZOLKIN_EPOCH
    let diff = tzolkin_count - haab_count
    if modulo(diff, 5) == 0:
        return date - modulo(date - haab_count - (365 * diff), 18980)
    else:
        raise newException(ValueError, BOGUS)


type calAztecXihuitlDate = object
    month: int
    day: int

# see lines 2170-2173 in calendrica-3.0.cl
proc aztec_xihuitl_date*(month, day: int): calAztecXihuitlDate =
    ## Return an Aztec xihuitl date data structure.
    return calAztecXihuitlDate(month: month, day: day)


# see lines 2175-2177 in calendrica-3.0.cl
proc aztec_xihuitl_month*(date: calAztecXihuitlDate): int = 
    ## Return the month field of an Aztec xihuitl date = [month, day].
    return date.month


# see lines 2179-2181 in calendrica-3.0.cl
proc aztec_xihuitl_day*(date: calAztecXihuitlDate): int =
    ## Return the day field of an Aztec xihuitl date = [month, day].
    return date.day


type calAztecTonalpoHualliDate = object
    number: int
    name: int

# see lines 2183-2186 in calendrica-3.0.cl
proc aztec_tonalpohualli_date*(number, name: int): calAztecTonalpoHualliDate =
    ## Return an Aztec tonalpohualli date data structure.
    return calAztecTonalpoHualliDate(number: number, name: name)

# see lines 2188-2191 in calendrica-3.0.cl
proc aztec_tonalpohualli_number*(date: calAztecTonalpoHualliDate): int =
    ## Return the number field of an Aztec tonalpohualli
    ## date = [number, name]
    return date.number

# see lines 2193-2195 in calendrica-3.0.cl
proc aztec_tonalpohualli_name*(date: calAztecTonalpoHualliDate): int =
    ## Return the name field of an Aztec tonalpohualli
    ## date = [number, name].
    return date.name


type calAztecXiuhmolpilliDesignation = object
    number: int
    name: int

# see lines 2197-2200 in calendrica-3.0.cl
proc aztec_xiuhmolpilli_designation*(number, name: int): calAztecXiuhmolpilliDesignation =
    ## Return an Aztec xiuhmolpilli date data structure.
    return calAztecXiuhmolpilliDesignation(number: number, name: name)


# see lines 2202-2205 in calendrica-3.0.cl
proc aztec_xiuhmolpilli_number*(date: calAztecXiuhmolpilliDesignation): int =
    ## Return the number field of an Aztec xiuhmolpilli
    ## date = [number, name].
    return date.number


# see lines 2207-2210 in calendrica-3.0.cl
proc aztec_xiuhmolpilli_name*(date: calAztecXiuhmolpilliDesignation): int =
    ## Return the name field of an Aztec xiuhmolpilli
    ## date = [number, name].
    return date.name


# see lines 2212-2215 in calendrica-3.0.cl
const AZTEC_CORRELATION = fixed_from_julian(julian_date(1521, AUGUST, 13))

# see lines 2217-2223 in calendrica-3.0.cl
proc aztec_xihuitl_ordinal*(x_date: calAztecXihuitlDate): int =
    ## Return the number of elapsed days into cycle of Aztec xihuitl
    ## date x_date.
    let day   = aztec_xihuitl_day(x_date)
    let month = aztec_xihuitl_month(x_date)
    return  ((month - 1) * 20) + day - 1

# see lines 2225-2229 in calendrica-3.0.cl
const AZTEC_XIHUITL_CORRELATION = (AZTEC_CORRELATION -
                                   aztec_xihuitl_ordinal(aztec_xihuitl_date(11, 2)))


# see lines 2231-2237 in calendrica-3.0.cl
proc aztec_xihuitl_from_fixed*(date: int): calAztecXihuitlDate =
    ## Return Aztec xihuitl date of fixed date date.
    let count = modulo(date - AZTEC_XIHUITL_CORRELATION, 365)
    let day   = modulo(count, 20) + 1
    let month = quotient(count, 20) + 1
    return aztec_xihuitl_date(month, day)


# see lines 2239-2246 in calendrica-3.0.cl
proc aztec_xihuitl_on_or_before*(xihuitl: calAztecXihuitlDate, date: int): int =
    ## Return fixed date of latest date on or before fixed date date
    ## that is Aztec xihuitl date xihuitl.
    return (date -
            modulo(date -
                  AZTEC_XIHUITL_CORRELATION -
                  aztec_xihuitl_ordinal(xihuitl), 365))


# see lines 2248-2255 in calendrica-3.0.cl
proc aztec_tonalpohualli_ordinal*(t_date: calAztecTonalpoHualliDate): int =
    ## Return the number of days into Aztec tonalpohualli cycle of t_date.
    let number = aztec_tonalpohualli_number(t_date)
    let name   = aztec_tonalpohualli_name(t_date)
    return modulo(number - 1 + 39 * (number - name), 260)


# see lines 2257-2262 in calendrica-3.0.cl
const AZTEC_TONALPOHUALLI_CORRELATION = (AZTEC_CORRELATION -
                                         aztec_tonalpohualli_ordinal(
                                         aztec_tonalpohualli_date(1, 5)))


# see lines 2264-2270 in calendrica-3.0.cl
proc aztec_tonalpohualli_from_fixed*(date: int): calAztecTonalpoHualliDate =
    ## Return Aztec tonalpohualli date of fixed date date.
    let count  = date - AZTEC_TONALPOHUALLI_CORRELATION + 1
    let number = amod(count, 13)
    let name   = amod(count, 20)
    return aztec_tonalpohualli_date(number, name)


# see lines 2272-2280 in calendrica-3.0.cl
proc aztec_tonalpohualli_on_or_before*(tonalpohualli: calAztecTonalpoHualliDate, date: int): int =
    ## Return fixed date of latest date on or before fixed date date
    ## that is Aztec tonalpohualli date tonalpohualli.
    return (date -
            modulo(date -
                  AZTEC_TONALPOHUALLI_CORRELATION -
                  aztec_tonalpohualli_ordinal(tonalpohualli), 260))

# see lines 2282-2303 in calendrica-3.0.cl
proc aztec_xihuitl_tonalpohualli_on_or_before*(xihuitl: calAztecXihuitlDate, 
                                              tonalpohualli: calAztecTonalpoHualliDate, 
                                              date: int): int =
    ## Return fixed date of latest xihuitl_tonalpohualli combination
    ## on or before date date.  That is the date on or before
    ## date date that is Aztec xihuitl date xihuitl and
    ## tonalpohualli date tonalpohualli.
    ## Returns BOGUS for impossible combinations.
    let xihuitl_count = aztec_xihuitl_ordinal(xihuitl) + AZTEC_XIHUITL_CORRELATION
    let tonalpohualli_count = (aztec_tonalpohualli_ordinal(tonalpohualli) +
                               AZTEC_TONALPOHUALLI_CORRELATION)
    let diff = tonalpohualli_count - xihuitl_count
    if modulo(diff, 5) == 0:
        return date - modulo(date - xihuitl_count - (365 * diff), 18980)
    else:
        raise newException(ValueError, BOGUS)

# see lines 2305-2316 in calendrica-3.0.cl
proc aztec_xiuhmolpilli_from_fixed*(date: int): calAztecTonalpoHualliDate =
    ## Return designation of year containing fixed date date.
    ## Returns BOGUS for nemontemi.
    let x = aztec_xihuitl_on_or_before(aztec_xihuitl_date(18, 20), date + 364)
    let month = aztec_xihuitl_month(aztec_xihuitl_from_fixed(date))
    if month == 19:
        raise newException(ValueError, BOGUS)
    else:
        return aztec_tonalpohualli_from_fixed(x)


###################################
## old hindu calendars algorithms #
###################################

type oHinduDate = object
    year: int
    month: int
    leap: bool
    day: int


# see lines 2321-2325 in calendrica-3.0.cl
proc old_hindu_lunar_date*(year, month: int, leap: bool, day: int): oHinduDate = 
    ## Return an Old Hindu lunar date data structure.
    return oHinduDate(year: year, month: month, leap: leap, day: day)


# see lines 2327-2329 in calendrica-3.0.cl
proc old_hindu_lunar_month*(date: oHinduDate): int =
    ## Return the month field of an Old Hindu lunar
    ## date = [year, month, leap, day].
    return date.month


# see lines 2331-2333 in calendrica-3.0.cl
proc old_hindu_lunar_leap*(date: oHinduDate): bool = 
    ## Return the leap field of an Old Hindu lunar
    ## date = [year, month, leap, day].
    return date.leap


# see lines 2335-2337 in calendrica-3.0.cl
proc old_hindu_lunar_day*(date: oHinduDate): int =
    ## Return the day field of an Old Hindu lunar
    ## date = [year, month, leap, day].
    return date.day


# see lines 2339-2341 in calendrica-3.0.cl
proc old_hindu_lunar_year*(date: oHinduDate): int =
    ## Return the year field of an Old Hindu lunar
    ## date = [year, month, leap, day].
    return date.year


# see lines 2343-2346 in calendrica-3.0.cl
proc hindu_solar_date*(year, month, day: int): calDate =
    ## Return an Hindu solar date data structure.
    return calDate(year: year, month: month, day: day)


# see lines 2348-2351 in calendrica-3.0.cl
const HINDU_EPOCH = fixed_from_julian(julian_date(bce(3102), FEBRUARY, 18))

# see lines 2358-2361 in calendrica-3.0.cl
const ARYA_SOLAR_YEAR = 1577917500/4320000

# see lines 2363-2366 in calendrica-3.0.cl
const ARYA_SOLAR_MONTH = ARYA_SOLAR_YEAR / 12


# see lines 2353-2356 in calendrica-3.0.cl
proc hindu_day_count*(date: int): int =
    ## Return elapsed days (Ahargana) to date date since Hindu epoch (KY).
    return date - HINDU_EPOCH


# see lines 2368-2378 in calendrica-3.0.cl
proc old_hindu_solar_from_fixed*(date: int): calDate =
    ## Return Old Hindu solar date equivalent to fixed date date.
    let sun   = hindu_day_count(date).float64 + days_from_hours(6)
    let year  = quotient(sun, ARYA_SOLAR_YEAR)
    let month = modulo(quotient(sun, ARYA_SOLAR_MONTH), 12) + 1
    let day   = ifloor(modulo(sun, ARYA_SOLAR_MONTH)) + 1
    return hindu_solar_date(year, month, day)


# see lines 2380-2390 in calendrica-3.0.cl
# The following
#      from math import ceil as ceiling
# is not ok, the corresponding CL code
# uses CL ceiling which always returns and integer, while
# ceil from math module always returns a float...so I redefine it
proc ceiling[T](n:T): int =
    ## Return the integer rounded towards +infinitum of n.
    return int(ceil(n))


proc fixed_from_old_hindu_solar*(s_date: calDate): int =
    ## Return fixed date corresponding to Old Hindu solar date s_date.
    let month = standard_month(s_date).float64
    let day   = standard_day(s_date).float64
    let year  = standard_year(s_date).float64
    return ceiling(HINDU_EPOCH.float64         +
                year * ARYA_SOLAR_YEAR         +
                (month - 1) * ARYA_SOLAR_MONTH +
                day + days_from_hours(-30))

# see lines 2392-2395 in calendrica-3.0.cl
const ARYA_LUNAR_MONTH = 1577917500.float64 / 53433336.float64

# see lines 2397-2400 in calendrica-3.0.cl
const ARYA_LUNAR_DAY =  ARYA_LUNAR_MONTH / 30.float64


# see lines 2402-2409 in calendrica-3.0.cl
proc is_old_hindu_lunar_leap_year*(l_year: int): bool =
    ## Return True if l_year is a leap year on the
    ## old Hindu calendar.
    return modulo(l_year.float64 * ARYA_SOLAR_YEAR - ARYA_SOLAR_MONTH,
                  ARYA_LUNAR_MONTH) >= 23902504679.float64 / 1282400064.float64


# see lines 2411-2431 in calendrica-3.0.cl
proc old_hindu_lunar_from_fixed*(date: int): oHinduDate =
    ## Return Old Hindu lunar date equivalent to fixed date date.
    let sun = hindu_day_count(date).float64 + days_from_hours(6)
    let new_moon = sun - modulo(sun, ARYA_LUNAR_MONTH)
    let leap = (((ARYA_SOLAR_MONTH - ARYA_LUNAR_MONTH) >=
                 modulo(new_moon, ARYA_SOLAR_MONTH)) and
                (modulo(new_moon, ARYA_SOLAR_MONTH) > 0))
    let month = modulo(ceiling(new_moon / ARYA_SOLAR_MONTH), 12) + 1
    let day = modulo(quotient(sun, ARYA_LUNAR_DAY), 30) + 1
    let year = ceiling((new_moon + ARYA_SOLAR_MONTH) / ARYA_SOLAR_YEAR) - 1
    return old_hindu_lunar_date(year, month, leap, day)

# see lines 2433-2460 in calendrica-3.0.cl
proc fixed_from_old_hindu_lunar*(l_date: oHinduDate): int =
    ## Return fixed date corresponding to Old Hindu lunar date l_date.
    let year  = old_hindu_lunar_year(l_date)
    let month = old_hindu_lunar_month(l_date)
    let leap  = old_hindu_lunar_leap(l_date)
    let day   = old_hindu_lunar_day(l_date).float64
    let mina  = ((12 * year) - 1).float64 * ARYA_SOLAR_MONTH
    let lunar_new_year = ARYA_LUNAR_MONTH * (quotient(mina, ARYA_LUNAR_MONTH) + 1).float64

    var temp: float64
    if ((not leap) and 
        (ceiling((lunar_new_year - mina) / (ARYA_SOLAR_MONTH - ARYA_LUNAR_MONTH)) <= month)):
        temp = month.float64
    else:
        temp = (month - 1).float64
    temp = (HINDU_EPOCH.float64 + 
            lunar_new_year +
            (ARYA_LUNAR_MONTH * temp) +
            ((day - 1) * ARYA_LUNAR_DAY) +
            days_from_hours(-6))
    return ceiling(temp)

# see lines 2462-2466 in calendrica-3.0.cl
const ARYA_JOVIAN_PERIOD =  1577917500.float64 / 364224.float64

# see lines 2468-2473 in calendrica-3.0.cl
proc jovian_year*(date: int): int =
    ## Return year of Jupiter cycle at fixed date date.
    return amod(quotient(hindu_day_count(date), ARYA_JOVIAN_PERIOD / 12) + 27,
                60)

################################
# balinese calendar algorithms #
################################
# see lines 2478-2481 in calendrica-3.0.cl
type calBalDate = object
    luang: bool
    dwiwara: int
    triwara: int
    caturwara: int
    pancawara: int
    sadwara: int
    saptawara: int
    asatawara: int
    sangawara: int
    dasawara: int


proc balinese_date*(b1: bool, b2, b3, b4, b5, b6, b7, b8, b9, b0: int): calBalDate =
    ## Return a Balinese date data structure
    result.luang = b1
    result.dwiwara = b2
    result.triwara = b3
    result.caturwara = b4
    result.pancawara = b5
    result.sadwara = b6
    result.saptawara = b7
    result.asatawara = b8
    result.sangawara = b9
    result.dasawara = b0
    return result

# see lines 2483-2485 in calendrica-3.0.cl
proc bali_luang*(b_date: calBalDate): bool =
    return b_date.luang

# see lines 2487-2489 in calendrica-3.0.cl
proc bali_dwiwara*(b_date: calBalDate): int =
    return b_date.dwiwara

# see lines 2491-2493 in calendrica-3.0.cl
proc bali_triwara*(b_date: calBalDate): int =
    return b_date.triwara

# see lines 2495-2497 in calendrica-3.0.cl
proc bali_caturwara*(b_date: calBalDate): int =
    return b_date.caturwara

# see lines 2499-2501 in calendrica-3.0.cl
proc bali_pancawara*(b_date: calBalDate): int =
    return b_date.pancawara

# see lines 2503-2505 in calendrica-3.0.cl
proc bali_sadwara*(b_date: calBalDate): int =
    return b_date.sadwara

# see lines 2507-2509 in calendrica-3.0.cl
proc bali_saptawara*(b_date: calBalDate): int =
    return b_date.saptawara

# see lines 2511-2513 in calendrica-3.0.cl
proc bali_asatawara*(b_date: calBalDate): int =
    return b_date.asatawara

# see lines 2513-2517 in calendrica-3.0.cl
proc bali_sangawara*(b_date: calBalDate): int =
    return b_date.sangawara

# see lines 2519-2521 in calendrica-3.0.cl
proc bali_dasawara*(b_date: calBalDate): int =
    return b_date.dasawara

# see lines 2523-2526 in calendrica-3.0.cl
const BALI_EPOCH = fixed_from_jd(146)

# see lines 2528-2531 in calendrica-3.0.cl
proc bali_day_from_fixed*(date: int): int =
    ## Return the position of date date in 210_day Pawukon cycle.
    return modulo(date - BALI_EPOCH, 210)

proc even[T](i: T): bool =
    return modulo(i, 2.T) == 0

proc odd[T](i: T): bool =
    return not even(i)


# see lines 2543-2546 in calendrica-3.0.cl
proc bali_triwara_from_fixed*(date: int): int =
    ## Return the position of date date in 3_day Balinese cycle.
    return modulo(bali_day_from_fixed(date), 3) + 1

# see lines 2553-2556 in calendrica-3.0.cl
proc bali_pancawara_from_fixed*(date: int): int =
    ## Return the position of date date in 5_day Balinese cycle.
    return amod(bali_day_from_fixed(date) + 2, 5)

# see lines 2558-2561 in calendrica-3.0.cl
proc bali_sadwara_from_fixed*(date: int): int =
    ## Return the position of date date in 6_day Balinese cycle.
    return modulo(bali_day_from_fixed(date), 6) + 1

# see lines 2563-2566 in calendrica-3.0.cl
proc bali_saptawara_from_fixed*(date: int): int =
    ## Return the position of date date in Balinese week.
    return modulo(bali_day_from_fixed(date), 7) + 1

# see lines 2568-2576 in calendrica-3.0.cl
proc bali_asatawara_from_fixed*(date: int): int =
    ## Return the position of date date in 8_day Balinese cycle.
    let day = bali_day_from_fixed(date)
    return modulo(max(6, 4 + modulo(day - 70, 210)), 8) + 1

# see lines 2548-2551 in calendrica-3.0.cl
proc bali_caturwara_from_fixed*(date: int): int =
    ## Return the position of date date in 4_day Balinese cycle.
    return amod(bali_asatawara_from_fixed(date), 4)

# see lines 2578-2583 in calendrica-3.0.cl
proc bali_sangawara_from_fixed*(date: int): int =
    ## Return the position of date date in 9_day Balinese cycle.
    return modulo(max(0, bali_day_from_fixed(date) - 3), 9) + 1

# see lines 2585-2594 in calendrica-3.0.cl
proc bali_dasawara_from_fixed*(date: int): int =
    ## Return the position of date date in 10_day Balinese cycle.
    let i = bali_pancawara_from_fixed(date) - 1
    let j = bali_saptawara_from_fixed(date) - 1
    return modulo(1 + [5, 9, 7, 4, 8][i] + [5, 4, 3, 7, 8, 6, 9][j], 10)

# see lines 2538-2541 in calendrica-3.0.cl
proc bali_dwiwara_from_fixed*(date: int): int =
    ## Return the position of date date in 2_day Balinese cycle.
    return amod(bali_dasawara_from_fixed(date), 2)

# see lines 2533-2536 in calendrica-3.0.cl
proc bali_luang_from_fixed*(date: int): bool =
    ## Check membership of date date in "1_day" Balinese cycle.
    return even(bali_dasawara_from_fixed(date))

# see lines 2596-2609 in calendrica-3.0.cl
proc bali_pawukon_from_fixed*(date: int ): calBalDate = 
    ## Return the positions of date date in ten cycles of Balinese Pawukon
    ## calendar.
    return balinese_date(bali_luang_from_fixed(date),
                         bali_dwiwara_from_fixed(date),
                         bali_triwara_from_fixed(date),
                         bali_caturwara_from_fixed(date),
                         bali_pancawara_from_fixed(date),
                         bali_sadwara_from_fixed(date),
                         bali_saptawara_from_fixed(date),
                         bali_asatawara_from_fixed(date),
                         bali_sangawara_from_fixed(date),
                         bali_dasawara_from_fixed(date))


# see lines 2611-2614 in calendrica-3.0.cl
proc bali_week_from_fixed*(date: int): int =
    ## Return the  week number of date date in Balinese cycle.
    return quotient(bali_day_from_fixed(date), 7) + 1

# see lines 2616-2630 in calendrica-3.0.cl
proc bali_on_or_before*(b_date: calBalDate, date: int): int =
    ## Return last fixed date on or before date with Pawukon date b_date.
    let a5 = bali_pancawara(b_date) - 1
    let a6 = bali_sadwara(b_date)   - 1
    let b7 = bali_saptawara(b_date) - 1
    let b35 = modulo(a5 + 14 + (15 * (b7 - a5)), 35)
    let days = a6 + (36 * (b35 - a6))
    let cap_Delta = bali_day_from_fixed(0)
    return date - modulo(date + cap_Delta - days, 210)

# see lines 2632-2646 in calendrica-3.0.cl
proc positions_in_range*(n, c, cap_Delta: int, range: tuple): seq[int] =
    ## Return the list of occurrences of n-th day of c-day cycle
    ## in range.
    ## cap_Delta is the position in cycle of RD 0.
    result = @[]
    let a = start(range)
    let b = endr(range)
    var pos = a + modulo(n - a - cap_Delta - 1, c)

    if (pos <= b): 
        result.add(pos)
        result.add(positions_in_range(n, c, cap_Delta, interval(pos + 1, b)))

# see lines 2648-2654 in calendrica-3.0.cl
proc kajeng_keliwon*(g_year: int): seq[int] =
    ## Return the occurrences of Kajeng Keliwon (9th day of each
    ## 15_day subcycle of Pawukon) in Gregorian year g_year.
    let year = gregorian_year_range(g_year)
    let cap_Delta = bali_day_from_fixed(0)
    return positions_in_range(9, 15, cap_Delta, year)

# see lines 2656-2662 in calendrica-3.0.cl
proc tumpek*(g_year: int): seq[int] =
    ## Return the occurrences of Tumpek (14th day of Pawukon and every
    ## 35th subsequent day) within Gregorian year g_year.
    let year = gregorian_year_range(g_year)
    let cap_Delta = bali_day_from_fixed(0)
    return positions_in_range(14, 35, cap_Delta, year)


#######################
## Time and Astronomy #
#######################

# see lines 2667-2670 in calendrica-3.0.cl
proc days_from_hours*(x: int|float64): float64 =
    ## Return the number of days given x hours.
    return x.float64 / 24.0

# see lines 2672-2675 in calendrica-3.0.cl
proc days_from_seconds*[T](x: T): float64 =
    ## Return the number of days given x seconds.
    return x / 24 / 60 / 60

# see lines 2677-2680 in calendrica-3.0.cl
proc mt(x: int|float64): float64 =
    ## Return x as meters.
    return x.float64

# see lines 2682-2686 in calendrica-3.0.cl
proc deg[T](x: T): float64 =
    ## Return the degrees in angle x.
    return x.float64

# see lines 2688-2690 in calendrica-3.0.cl
proc secs*[T](x: T): float64 =
    ## Return the seconds in angle x.
    return x / 3600

# see lines 2692-2696 in calendrica-3.0.cl
proc angle*(d, m, s: float64): float64 =
    ## Return an angle data structure
    ## from d degrees, m arcminutes and s arcseconds.
    ## This assumes that negative angles specifies negative d, m and s.
    return d + ((m + (s / 60.float64)) / 60.float64)

# see lines 2698-2701 in calendrica-3.0.cl
proc normalized_degrees*(theta: float64): float64 =
    ## Return a normalize angle theta to range [0,360) degrees.
    return modulo(theta, 360.0)

# see lines 2703-2706 in calendrica-3.0.cl
proc normalized_degrees_from_radians*(theta: float64): float64 =
    ## Return normalized degrees from radians, theta.
    ## Function 'degrees' comes from mpmath. 
    ## we don't have mpmath in Nim so we revert to the original CL formulation
    return normalized_degrees(theta / PI / (1.0 / 180.0))


# # see lines 2708-2711 in calendrica-3.0.cl
# def radians_from_degrees(theta):
#     pass
# from mpmath import radians as radians_from_degrees
proc radians_from_degrees*(theta: float64): float64 =
    return normalized_degrees(theta) * PI * (1.0 / 180.0)

# see lines 2713-2716 in calendrica-3.0.cl
proc sin_degrees*(theta: float64): float64 =
    ## Return sine of theta (given in degrees).
    #from math import sin
    return sin(radians_from_degrees(theta))

# see lines 2718-2721 in calendrica-3.0.cl
proc cosine_degrees*(theta: float64): float64 =
    ## Return cosine of theta (given in degrees).
    #from math import cos
    return cos(radians_from_degrees(theta))

# from errata20091230.pdf entry 112
let cos_degrees = cosine_degrees


# see lines 2723-2726 in calendrica-3.0.cl
proc tangent_degrees*(theta: float64): float64 =
    ## Return tangent of theta (given in degrees).
    return tan(radians_from_degrees(theta))

# from errata20091230.pdf entry 112
let tan_degrees = tangent_degrees


proc signum[T](a: T): float64 =
    if a > 0:
        return 1
    elif a == 0:
        return 0
    else:
        return -1

#-----------------------------------------------------------
# NOTE: arc[tan|sin|cos] casted with degrees given CL code
#       returns angles [0, 360), see email from Dershowitz
#       after my request for clarification
#-----------------------------------------------------------

# see lines 2728-2739 in calendrica-3.0.cl
# def arctan_degrees(y, x):
#      Arctangent of y/x in degrees.
#     from math import atan2
#     return normalized_degrees_from_radians(atan2(x, y))


proc arctan_degrees(y, x: float64): float64 =
   ## Arctangent of y/x in degrees.
   if (x == 0) and (y != 0):
       return modulo(signum(y) * deg(90.float64), 360.float64)
   else:
       let alpha = normalized_degrees_from_radians(arctan(y / x))
       if x >= 0:
           return alpha
       else:
           return modulo(alpha + deg((180.float64)), 360.float64)


# see lines 2741-2744 in calendrica-3.0.cl
proc arcsin_degrees(x: float64): float64 =
    ## Return arcsine of x in degrees.
    #from math import asin
    return normalized_degrees_from_radians(arcsin(x))

# see lines 2746-2749 in calendrica-3.0.cl
proc arccos_degrees(x: float64): float64 =
    ## Return arccosine of x in degrees.
    #from math import acos
    return normalized_degrees_from_radians(arccos(x))


type calLocationData = object
    latitude: float64
    longitude: float64
    elevation: float64
    zone: float64

# see lines 3297-3300 in calendrica-3.0.cl
const SPRING = deg(0)

# see lines 3302-3305 in calendrica-3.0.cl
const SUMMER = deg(90)

# see lines 3307-3310 in calendrica-3.0.cl
const AUTUMN = deg(180)

# see lines 3312-3315 in calendrica-3.0.cl
const WINTER = deg(270)

# see lines 2751-2753 in calendrica-3.0.cl
proc location*(latitude, longitude, elevation, zone: float64): calLocationData =
    ## Return a location data structure.
    return calLocationData(latitude: latitude, 
                           longitude: longitude, 
                           elevation: elevation, 
                           zone: zone)

# see lines 2755-2757 in calendrica-3.0.cl
proc latitude*(location: calLocationData): float64 =
    ## Return the latitude field of a location.
    return location.latitude

# see lines 2759-2761 in calendrica-3.0.cl
proc longitude*(location: calLocationData): float64 =
    ## Return the longitude field of a location.
    return location.longitude

# see lines 2763-2765 in calendrica-3.0.cl
proc elevation*(location: calLocationData): float64 =
    ## Return the elevation field of a location.
    return location.elevation

# see lines 2767-2769 in calendrica-3.0.cl
proc zone*(location: calLocationData): float64 =
    ## Return the timezone field of a location.
    return location.zone

# see lines 2771-2775 in calendrica-3.0.cl
const MECCA = location(angle(21, 25, 24), angle(39, 49, 24), mt(298), days_from_hours(3))

# see lines 5898-5901 in calendrica-3.0.cl
const JERUSALEM = location(31.8, 35.2, mt(800), days_from_hours(2))

const BRUXELLES = location(angle(4, 21, 17), angle(50, 50, 47), mt(800), days_from_hours(1))

const URBANA = location(40.1,
                  -88.2,
                  mt(225),
                  days_from_hours(-6))

const GREENWHICH = location(51.4777815,
                      0,
                      mt(46.9),
                      days_from_hours(0))


proc ecliptical_from_equatorial*(ra, declination, obliquity: float64): (float64, float64) =
    ## Convert equatorial coordinates (in degrees) to ecliptical ones.
    ## 'declination' is the declination,
    ## 'ra' is the right ascension and
    ## 'obliquity' is the obliquity of the ecliptic.
    ## NOTE: if 'apparent' right ascension and declination are used, then 'true'
    ##      obliquity should be input.
    ##

    let co = cos_degrees(obliquity)
    let so = sin_degrees(obliquity)
    let sa = sin_degrees(ra)
    let lon = normalized_degrees_from_radians(
        arctan2(sa*co + tan_degrees(declination)*so, cos_degrees(ra)))
    let lat = arcsin_degrees(
            sin_degrees(declination)*co -
            cos_degrees(declination)*so*sa)
    return (lon, lat)


proc equatorial_from_ecliptical*(longitude, latitude, obliquity: float64): (float64, float64) =
    ## Convert ecliptical coordinates (in degrees) to equatorial ones.
    ## 'longitude' is the ecliptical longitude,
    ## 'latitude'  is the ecliptical latitude and
    ## 'obliquity' is the obliquity of the ecliptic.
    ## NOTE: resuting 'ra' and 'declination' will be referred to the same equinox
    ##       as the one of input ecliptical longitude and latitude.
    
    let co = cos_degrees(obliquity)
    let so = sin_degrees(obliquity)
    let sl = sin_degrees(longitude)
    let ra = normalized_degrees_from_radians(
                arctan2(sl*co - tan_degrees(latitude)*so,
                cos_degrees(longitude)))
    let dec = arcsin_degrees(
                sin_degrees(latitude)*co +
                cos_degrees(latitude)*so*sl)
    return (ra, dec)


proc horizontal_from_equatorial*(H, declination, latitude: float64): (float64, float64) =
    ## Convert equatorial coordinates (in degrees) to horizontal ones.
    ## Return 'azimuth' and 'altitude'.
    ## 'H'            is the local hour angle,
    ## 'declination'  is the declination,
    ## 'latitude'     is the observer's geographic latitude.
    ## NOTE: 'azimuth' is measured westward from the South.
    ## NOTE: This is not a good formula for using near the poles.
    
    let ch = cos_degrees(H)
    let sl = sin_degrees(latitude)
    let cl = cos_degrees(latitude)
    let A = normalized_degrees_from_radians(
                arctan2(sin_degrees(H), 
                        ch * sl - tan_degrees(declination) * cl))
    let h = arcsin_degrees(sl * sin_degrees(declination) + 
                           cl * cos_degrees(declination) * ch)
    return (A, h)

proc equatorial_from_horizontal*(A, h, phi: float64): (float64, float64) =
    ## Convert equatorial coordinates (in degrees) to horizontal ones.
    ## Return 'local hour angle' and 'declination'.
    ## 'A'   is the azimuth,
    ## 'h'   is the altitude,
    ## 'phi' is the observer's geographical latitude.
    ## NOTE: 'azimuth' is measured westward from the South.
    
    let H = normalized_degrees_from_radians(
                arctan2(sin_degrees(A), 
                        (cos_degrees(A) * sin_degrees(phi) + 
                        tan_degrees(h) * cos_degrees(phi))))
    let delta = arcsin_degrees(sin_degrees(phi) * sin_degrees(h) - 
                               cos_degrees(phi) * cos_degrees(h) * cos_degrees(A))
    return (H, delta)


# see lines 2777-2797 in calendrica-3.0.cl
proc direction*(location, focus: calLocationData): float64 =
    ## Return the angle (clockwise from North) to face focus when
    ## standing in location, location.  Subject to errors near focus and
    ## its antipode.
    let phi = latitude(location)
    let phi_prime = latitude(focus)
    let psi = longitude(location)
    let psi_prime = longitude(focus)
    let y = sin_degrees(psi_prime - psi)
    let x = ((cosine_degrees(phi) * tangent_degrees(phi_prime)) -
            (sin_degrees(phi)    * cosine_degrees(psi - psi_prime)))
    if ((x == 0.0 and y == 0.0) or (phi_prime == deg(90.float64))):
        return deg(0.float64)
    elif (phi_prime == deg(-90.float64)):
        return deg(180.float64)
    else:
        return arctan_degrees(y, x)

# see lines 2799-2803 in calendrica-3.0.cl
proc standard_from_universal*(tee_rom_u: float64, location: calLocationData): float64 =
    ## Return standard time from tee_rom_u in universal time at location.
    return tee_rom_u + zone(location)

# see lines 2805-2809 in calendrica-3.0.cl
proc universal_from_standard*(tee_rom_s: float64, location: calLocationData): float64 =
    ## Return universal time from tee_rom_s in standard time at location.
    return tee_rom_s - zone(location)

# see lines 2811-2815 in calendrica-3.0.cl
proc zone_from_longitude*(phi: float64): float64 =
    ## Return the difference between UT and local mean time at longitude
    ##'phi' as a fraction of a day.
    return phi / deg(360)

# see lines 2817-2820 in calendrica-3.0.cl
proc local_from_universal*(tee_rom_u: float64, location: calLocationData): float64 =
    ## Return local time from universal tee_rom_u at location, location.
    return tee_rom_u + zone_from_longitude(longitude(location))

# see lines 2822-2825 in calendrica-3.0.cl
proc universal_from_local*(tee_ell: float64, location: calLocationData): float64 =
    ## Return universal time from local tee_ell at location, location.
    return tee_ell - zone_from_longitude(longitude(location))

# see lines 2827-2832 in calendrica-3.0.cl
proc standard_from_local*(tee_ell: float64, location: calLocationData): float64 =
    ## Return standard time from local tee_ell at locale, location.
    return standard_from_universal(universal_from_local(tee_ell, location),
                                   location)

# see lines 2834-2839 in calendrica-3.0.cl
proc local_from_standard*(tee_rom_s: float64, location: calLocationData): float64 =
    ## Return local time from standard tee_rom_s at location, location.
    return local_from_universal(universal_from_standard(tee_rom_s, location),
                                location)

proc equation_of_time*(tee: float64): float64 {.gcsafe.}

# see lines 2841-2844 in calendrica-3.0.cl
proc apparent_from_local*(tee: float64, location: calLocationData): float64 =
    ## Return sundial time at local time tee at location, location.
    return tee + equation_of_time(universal_from_local(tee, location))

# see lines 2846-2849 in calendrica-3.0.cl
proc local_from_apparent*(tee: float64, location: calLocationData): float64 =
    ## Return local time from sundial time tee at location, location.
    return tee - equation_of_time(universal_from_local(tee, location))

# see lines 2851-2857 in calendrica-3.0.cl
proc midnight*(date: float64, location: calLocationData): float64 =
    ## Return standard time on fixed date, date, of true (apparent)
    ## midnight at location, location.
    return standard_from_local(local_from_apparent(date, location), location)

# see lines 2859-2864 in calendrica-3.0.cl
proc midday*(date: float64, location: calLocationData): float64 =
    ## Return standard time on fixed date, date, of midday
    ## at location, location.
    return standard_from_local(local_from_apparent(date + days_from_hours(mpf(12)),
                                                   location), location)

proc dynamical_from_universal*(tee: float64): float64 {.gcsafe.}

# see lines 3111-3114 in calendrica-3.0.cl
const J2000 = days_from_hours(mpf(12)) + gregorian_new_year(2000).float64


# see lines 2866-2870 in calendrica-3.0.cl
proc julian_centuries*(tee: float64): float64 = 
    ## Return Julian centuries since 2000 at moment tee.
    return (dynamical_from_universal(tee) - J2000) / mpf(36525)

# see lines 2872-2880 in calendrica-3.0.cl
proc obliquity*(tee: float64): float64 =
    ## Return (mean) obliquity of ecliptic at moment tee.
    let c = julian_centuries(tee)
    return (angle(23.0, 26.0, mpf(21.448)) +
            poly(c, [mpf(0),
                     angle(0, 0, mpf(-46.8150)),
                     angle(0, 0, mpf(-0.00059)),
                     angle(0, 0, mpf(0.001813))]))

proc precise_obliquity*(tee: float64): float64 =
    ## Return precise (mean) obliquity of ecliptic at moment tee.
    let u = julian_centuries(tee)/100
    #assert(abs(u) < 1,
    #       'Error! This formula is valid for +/-10000 years around J2000.0')
    return (poly(u, [angle(23, 26, mpf(21.448)),
                     angle(0, 0, mpf(-4680.93)),
                     angle(0, 0, mpf(-   1.55)),
                     angle(0, 0, mpf(+1999.25)),
                     angle(0, 0, mpf(-  51.38)),
                     angle(0, 0, mpf(- 249.67)),
                     angle(0, 0, mpf(-  39.05)),
                     angle(0, 0, mpf(+   7.12)),
                     angle(0, 0, mpf(+  27.87)),
                     angle(0, 0, mpf(+   5.79)),
                     angle(0, 0, mpf(+   2.45))]))


# see lines 2882-2891 in calendrica-3.0.cl
proc declination*(tee, beta, lam: float64): float64 =
    ## Return declination at moment UT tee of objectat
    ## longitude 'lam' and latitude 'beta'.
    let varepsilon = obliquity(tee)
    return arcsin_degrees(
        (sin_degrees(beta) * cosine_degrees(varepsilon)) +
        (cosine_degrees(beta) * sin_degrees(varepsilon) * sin_degrees(lam)))

# see lines 2893-2903 in calendrica-3.0.cl
proc right_ascension*(tee, beta, lam: float64): float64 =
    ## Return right ascension at moment UT 'tee' of object at
    ## latitude 'lam' and longitude 'beta'.

    let varepsilon = obliquity(tee)
    return arctan_degrees(
        (sin_degrees(lam) * cosine_degrees(varepsilon)) -
        (tangent_degrees(beta) * sin_degrees(varepsilon)),
        cosine_degrees(lam)) 


proc solar_longitude*(tee: float64): float64 {.gcsafe.}

# see lines 2905-2920 in calendrica-3.0.cl
proc sine_offset*(tee: float64, location: calLocationData, alpha: float64): float64 =
    ## Return sine of angle between position of sun at 
    ## local time tee and when its depression is alpha at location, location.
    ## Out of range when it does not occur.
    let phi = latitude(location)
    let tee_prime = universal_from_local(tee, location)
    let delta = declination(tee_prime, deg(mpf(0)), solar_longitude(tee_prime))
    return ((tangent_degrees(phi) * tangent_degrees(delta)) +
            (sin_degrees(alpha) / (cosine_degrees(delta) *
                                   cosine_degrees(phi))))

# see lines 2922-2947 in calendrica-3.0.cl
proc approx_moment_of_depression*(tee: float64, 
                                 location: calLocationData, 
                                 alpha: float64, early: bool): float64 =
    ## Return the moment in local time near tee when depression angle
    ## of sun is alpha (negative if above horizon) at location;
    ## early is true when MORNING event is sought and false for EVENING.
    ## Returns BOGUS if depression angle is not reached.
    let ttry  = sine_offset(tee, location, alpha)
    let date = fixed_from_moment(tee).float64

    var alt: float64
    if (alpha >= 0.0):
        if early:
            alt = date
        else:
            alt = date + 1
    else:
        alt = date + days_from_hours(12)

    var value: float64
    if (abs(ttry) > 1.0):
        value = sine_offset(alt, location, alpha)
    else:
        value = ttry


    if (abs(value) <= 1.0):
        var temp = if early: -1.0 else: 1.0
        temp *= modulo(days_from_hours(12) + arcsin_degrees(value) / deg(360), 1.0) - days_from_hours(6)
        temp += date + days_from_hours(12)
        return local_from_apparent(temp, location)
    else:
        raise newException(ValueError, BOGUS)

# see lines 2949-2963 in calendrica-3.0.cl
proc moment_of_depression*(approx: float64, location: calLocationData, 
                          alpha: float64, early: bool): float64 =
    ## Return the moment in local time near approx when depression
    ## angle of sun is alpha (negative if above horizon) at location;
    ## early is true when MORNING event is sought, and false for EVENING.
    ## Returns BOGUS if depression angle is not reached.
    let tee = approx_moment_of_depression(approx, location, alpha, early)
        
    if (abs(approx - tee) < days_from_seconds(30)):
        return tee
    else:
        return moment_of_depression(tee, location, alpha, early)


# see lines 2965-2968 in calendrica-3.0.cl
const MORNING = true

# see lines 2970-2973 in calendrica-3.0.cl
const EVENING = false


# see lines 2975-2984 in calendrica-3.0.cl
proc dawn*(date: float64, location: calLocationData, alpha: float64): float64 =
    ## Return standard time in morning on fixed date date at
    ## location location when depression angle of sun is alpha.
    ## raises BOGUS if there is no dawn on date date.
    result = moment_of_depression(date + days_from_hours(6), location, alpha, MORNING)
    return standard_from_local(result, location)        


# see lines 2986-2995 in calendrica-3.0.cl
proc dusk*(date: float64, location: calLocationData, alpha: float64): float64 =
    ## Return standard time in evening on fixed date 'date' at
    ## location 'location' when depression angle of sun is alpha.
    ## raises BOGUS if there is no dusk on date 'date'.
    result = moment_of_depression(date + days_from_hours(18), location, alpha, EVENING)
    return standard_from_local(result, location)


# see lines 440-451 in calendrica-3.0.errata.cl
proc refraction*(tee: float64, location: calLocationData): float64 =
    ## Return refraction angle at location 'location' and time 'tee'.

    let h     = max(mt(0), elevation(location))
    let cap_R = mt(6.372E6)
    let dip   = arccos_degrees(cap_R / (cap_R + h))
    return angle(0, 50, 0) + dip + secs(19) * sqrt(h)


# see lines 2997-3007 in calendrica-3.0.cl
proc sunrise*(date: float64, location: calLocationData): float64 =
    ## Return Standard time of sunrise on fixed date 'date' at
    ## location 'location'.
    let alpha = refraction(date, location)
    return dawn(date, location, alpha)


# see lines 3009-3019 in calendrica-3.0.cl
proc sunset*(date: float64, location: calLocationData): float64 =
    ## Return standard time of sunset on fixed date 'date' at
    ## location 'location'.
    let alpha = refraction(date, location)
    return dusk(date, location, alpha)

proc topocentric_lunar_altitude*(tee: float64, location: calLocationData): float64 {.gcsafe.}

# see lines 453-458 in calendrica-3.0.errata.cl
proc observed_lunar_altitude*(tee: float64, location: calLocationData): float64 =
    ## Return the observed altitude of moon at moment, tee, and
    ## at location, location,  taking refraction into account.
    return topocentric_lunar_altitude(tee, location) + refraction(tee, location)

# see lines 460-467 in calendrica-3.0.errata.cl
proc moonrise*(date: int, location: calLocationData): float64 =
    ## Return the standard time of moonrise on fixed, date,
    ## and location, location.
    let t = universal_from_standard(date.float64, location)
    let waning = (lunar_phase(t) > deg(180))
    let alt = observed_lunar_altitude(t, location)
    let offset = alt / 360
    var approx: float64
    if (waning and (offset > 0)):
        approx =  t + 1 - offset
    elif waning:
        approx = t - offset
    else:
        approx = t + (1 / 2) + offset
    let rise = binary_search((approx - days_from_hours(3)).float64,
                             (approx + days_from_hours(3)).float64,
                             proc(hi, lo: float64):bool = ((hi - lo).float64 < days_from_hours(1 / 60)),
                             proc(x: float64):bool = observed_lunar_altitude(x, location) > deg(0))
    if rise < (t + 1):
        return standard_from_universal(rise, location)  
    else: 
        raise newException(ValueError, BOGUS)


proc urbana_sunset*(gdate: calDate): float64 =
    ## Return sunset time in Urbana, Ill, on Gregorian date 'gdate'.
    return time_from_moment(sunset(fixed_from_gregorian(gdate).float64, URBANA))

proc solar_longitude_after*(lam, tee: float64): float64 {.gcsafe.}

# from eq 13.38 pag. 191
proc urbana_winter*(g_year: int): float64 =
    ## Return standard time of the winter solstice in Urbana, Illinois, USA.
    return standard_from_universal(
               solar_longitude_after(
                   WINTER, 
                   fixed_from_gregorian(gregorian_date(g_year, JANUARY, 1)).float64),
               URBANA)


############################################
## astronomical lunar calendars algorithms #
############################################

# see lines 3021-3025 in calendrica-3.0.cl
proc jewish_dusk*(date: int, location: calLocationData): float64 =
    ## Return standard time of Jewish dusk on fixed date, date,
    ## at location, location, (as per Vilna Gaon).
    return dusk(date.float64, location, angle(4, 40, 0))


# see lines 3027-3031 in calendrica-3.0.cl
proc jewish_sabbath_ends*(date: int, location: calLocationData): float64 =
    ## Return standard time of end of Jewish sabbath on fixed date, date,
    ## at location, location, (as per Berthold Cohn).
    return dusk(date.float64, location, angle(7, 5, 0)) 


# see lines 3033-3042 in calendrica-3.0.cl
proc daytime_temporal_hour*(date: int, location: calLocationData): float64 =
    ## Return the length of daytime temporal hour on fixed date, date
    ## at location, location.
    ## Return BOGUS if there no sunrise or sunset on date, date.
    try:
        return (sunset(date.float64, location) - sunrise(date.float64, location)) / 12.0        
    except:
        echo getCurrentExceptionMsg()
        

# see lines 3044-3053 in calendrica-3.0.cl
proc nighttime_temporal_hour*(date: int, location: calLocationData): float64 =
    ## Return the length of nighttime temporal hour on fixed date, date,
    ## at location, location.
    ## Return BOGUS if there no sunrise or sunset on date, date.
    try:
        return (sunrise(date.float64 + 1, location) - sunset(date.float64, location)) / 12.0
    except:
        echo getCurrentExceptionMsg()
        

# see lines 3055-3073 in calendrica-3.0.cl
proc standard_from_sundial*(tee: float64, location: calLocationData): float64 =
    ## Return standard time of temporal moment, tee, at location, location.
    ## Return BOGUS if temporal hour is undefined that day.
    let date = fixed_from_moment(tee)
    let hour = 24 * modulo(tee, 1.0)
    var h: float64

    try:
        if (hour >= 6 and hour <= 18):
            h = daytime_temporal_hour(date, location)
        elif (hour < 6):
            h = nighttime_temporal_hour(date - 1, location)
        else:
            h = nighttime_temporal_hour(date, location)
    except:
        echo getCurrentExceptionMsg()
        return

    # return
    if (hour >= 6 and hour <= 18):
        return sunrise(date.float64, location) + ((hour - 6) * h)
    elif (hour < 6):
        return sunset(date.float64 - 1, location) + ((hour + 6) * h)
    else:
        return sunset(date.float64, location) + ((hour - 18) * h)


# see lines 3075-3079 in calendrica-3.0.cl
proc jewish_morning_end*(date: int, location: calLocationData): float64 =
    ## Return standard time on fixed date, date, at location, location,
    ## of end of morning according to Jewish ritual.
    return standard_from_sundial(date.float64 + days_from_hours(10), location)

# see lines 3081-3099 in calendrica-3.0.cl
proc asr*(date: int, location: calLocationData): float64 =
    ## Return standard time of asr on fixed date, date,
    ## at location, location.
    let noon = universal_from_standard(midday(date.float64, location), location)
    let phi = latitude(location)
    let delta = declination(noon, deg(0), solar_longitude(noon))
    let altitude = delta - phi - deg(90)
    let h = arctan_degrees(tangent_degrees(altitude),
                           2 * tangent_degrees(altitude) + 1)
    # For Shafii use instead:
    # tangent_degrees(altitude) + 1)

    return dusk(date.float64, location, -h)

##
############ 
## here start the code inspired by Meeus
##

proc ephemeris_correction*(tee: float64): float64 {.gcsafe.}

# see lines 3101-3104 in calendrica-3.0.cl
proc universal_from_dynamical*(tee: float64): float64 =
    ## Return Universal moment from Dynamical time, tee.
    return tee - ephemeris_correction(tee)


# see lines 3106-3109 in calendrica-3.0.cl
proc dynamical_from_universal*(tee: float64): float64 =
    ## Return Dynamical time at Universal moment, tee.
    return tee + ephemeris_correction(tee)


# see lines 3116-3126 in calendrica-3.0.cl
proc sidereal_from_moment*(tee: float64): float64 =
    ## Return the mean sidereal time of day from moment tee expressed
    ## as hour angle.  Adapted from "Astronomical Algorithms"
    ## by Jean Meeus, Willmann_Bell, Inc., 1991.
    let c = (tee - J2000) / mpf(36525)
    return modulo(poly(c, @[mpf(280.46061837),
                            mpf(36525) * mpf(360.98564736629),
                            mpf(0.000387933),
                            mpf(-1)/mpf(38710000)]),
                  360.0)

# see lines 3128-3130 in calendrica-3.0.cl
const MEAN_TROPICAL_YEAR = mpf(365.242189)

# see lines 3132-3134 in calendrica-3.0.cl
const MEAN_SIDEREAL_YEAR = mpf(365.25636)

# see lines 93-97 in calendrica-3.0.errata.cl
const MEAN_SYNODIC_MONTH = mpf(29.530588861)

# see lines 3140-3176 in calendrica-3.0.cl
proc ephemeris_correction*(tee: float64): float64 =
    ## Return Dynamical Time minus Universal Time (in days) for
    ## moment, tee.  Adapted from "Astronomical Algorithms"
    ## by Jean Meeus, Willmann_Bell, Inc., 1991.
    let year = gregorian_year_from_fixed(ifloor(tee))
    let c = gregorian_date_difference(gregorian_date(1900, JANUARY, 1),
                                      gregorian_date(year, JULY, 1)).float64 / mpf(36525)
    if (year >= 1988 and year <= 2019):
        return 1.0/86400.0 * (year - 1933).float64
    elif (year >= 1900 and year <= 1987):
        return poly(c, [mpf(-0.00002), mpf(0.000297), mpf(0.025184),
                        mpf(-0.181133), mpf(0.553040), mpf(-0.861938),
                        mpf(0.677066), mpf(-0.212591)])
    elif (year >= 1800 and year <= 1899):
        return poly(c, [mpf(-0.000009), mpf(0.003844), mpf(0.083563),
                        mpf(0.865736), mpf(4.867575), mpf(15.845535),
                        mpf(31.332267), mpf(38.291999), mpf(28.316289),
                        mpf(11.636204), mpf(2.043794)])
    elif (year >= 1700 and year <= 1799):
        return (1.0/86400.0 *
                poly((year - 1700).float64, [8.118780842, -0.005092142,
                                   0.003336121, -0.0000266484]))
    elif (year >= 1620 and year <= 1699):
        return (1.0/86400.0 *
                poly((year - 1600).float64,
                     [mpf(196.58333), mpf(-4.0675), mpf(0.0219167)]))
    else:
        let x = (days_from_hours(mpf(12)) +
             gregorian_date_difference(gregorian_date(1810, JANUARY, 1),
                                       gregorian_date(year, JANUARY, 1)).float64)
        return 1.0/86400.0 * (((x * x) / mpf(41048480)) - 15)

# see lines 3178-3207 in calendrica-3.0.cl
proc equation_of_time*(tee: float64): float64 =
    ## Return the equation of time (as fraction of day) for moment, tee.
    ## Adapted from "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 1991.
    let c = julian_centuries(tee).float64
    let lamb = poly(c, [mpf(280.46645), mpf(36000.76983), mpf(0.0003032)])
    let anomaly = poly(c, [mpf(357.52910), mpf(35999.05030),
                           mpf(-0.0001559), mpf(-0.00000048)])
    let eccentricity = poly(c, [mpf(0.016708617),
                            mpf(-0.000042037),
                            mpf(-0.0000001236)])
    let varepsilon = obliquity(tee)
    let y = pow(tangent_degrees(varepsilon / 2), 2)
    let equation = (((1.0/2.0) / PI) *
                (y * sin_degrees(2.0 * lamb) +
                 -2 * eccentricity * sin_degrees(anomaly) +
                 (4 * eccentricity * y * sin_degrees(anomaly) *
                  cosine_degrees(2.0 * lamb)) +
                 -0.5 * y * y * sin_degrees(4.0 * lamb) +
                 -1.25 * eccentricity * eccentricity * sin_degrees(2.0 * anomaly)))
    return signum(equation) * min(abs(equation), days_from_hours(mpf(12)))

proc nutation*(tee: float64): float64 {.gcsafe.}
proc aberration*(tee: float64): float64 {.gcsafe.}

# see lines 3209-3259 in calendrica-3.0.cl
proc solar_longitude*(tee: float64): float64 =
    ## Return the longitude of sun at moment 'tee'.
    ## Adapted from 'Planetary Programs and Tables from -4000 to +2800'
    ## by Pierre Bretagnon and Jean_Louis Simon, Willmann_Bell, Inc., 1986.
    ## See also pag 166 of 'Astronomical Algorithms' by Jean Meeus, 2nd Ed 1998,
    ## with corrections Jun 2005.
    let c = julian_centuries(tee)
    let coefficients = map([403406, 195207, 119433, 112392, 3891, 2819, 1721,
                    660, 350, 334, 314, 268, 242, 234, 158, 132, 129, 114,
                    99, 93, 86, 78,72, 68, 64, 46, 38, 37, 32, 29, 28, 27, 27,
                    25, 24, 21, 21, 20, 18, 17, 14, 13, 13, 13, 12, 10, 10, 10,
                    10], mpf)
    let multipliers = @[mpf(0.9287892), mpf(35999.1376958), mpf(35999.4089666),
                   mpf(35998.7287385), mpf(71998.20261), mpf(71998.4403),
                   mpf(36000.35726), mpf(71997.4812), mpf(32964.4678),
                   mpf(-19.4410), mpf(445267.1117), mpf(45036.8840), mpf(3.1008),
                   mpf(22518.4434), mpf(-19.9739), mpf(65928.9345),
                   mpf(9038.0293), mpf(3034.7684), mpf(33718.148), mpf(3034.448),
                   mpf(-2280.773), mpf(29929.992), mpf(31556.493), mpf(149.588),
                   mpf(9037.750), mpf(107997.405), mpf(-4444.176), mpf(151.771),
                   mpf(67555.316), mpf(31556.080), mpf(-4561.540),
                   mpf(107996.706), mpf(1221.655), mpf(62894.167),
                   mpf(31437.369), mpf(14578.298), mpf(-31931.757),
                   mpf(34777.243), mpf(1221.999), mpf(62894.511),
                   mpf(-4442.039), mpf(107997.909), mpf(119.066), mpf(16859.071),
                   mpf(-4.578), mpf(26895.292), mpf(-39.127), mpf(12297.536),
                   mpf(90073.778)]
    let addends = @[mpf(270.54861), mpf(340.19128), mpf(63.91854), mpf(331.26220),
               mpf(317.843), mpf(86.631), mpf(240.052), mpf(310.26), mpf(247.23),
               mpf(260.87), mpf(297.82), mpf(343.14), mpf(166.79), mpf(81.53),
               mpf(3.50), mpf(132.75), mpf(182.95), mpf(162.03), mpf(29.8),
               mpf(266.4), mpf(249.2), mpf(157.6), mpf(257.8),mpf(185.1),
               mpf(69.9),  mpf(8.0), mpf(197.1), mpf(250.4), mpf(65.3),
               mpf(162.7), mpf(341.5), mpf(291.6), mpf(98.5), mpf(146.7),
               mpf(110.0), mpf(5.2), mpf(342.6), mpf(230.9), mpf(256.1),
               mpf(45.3), mpf(242.9), mpf(115.2), mpf(151.8), mpf(285.3),
               mpf(53.3), mpf(126.6), mpf(205.7), mpf(85.9), mpf(146.1)]
    let lam = (deg(mpf(282.7771834)) +
           deg(mpf(36000.76953744)) * c +
           deg(mpf(0.000005729577951308232)) *
           sigma(@[coefficients, addends, multipliers],
                 proc(x:seq[float64]):float64 =  x[0] * sin_degrees(x[1] + (x[2] * c))))
    return modulo(lam + aberration(tee) + nutation(tee), 360.0)


proc geometric_solar_mean_longitude*(tee: float64): float64 =
    ## Return the geometric mean longitude of the Sun at moment, tee,
    ## referred to mean equinox of the date.
    let c = julian_centuries(tee)
    return poly(c, @[mpf(280.46646), mpf(36000.76983), mpf(0.0003032)])


# see lines 3261-3271 in calendrica-3.0.cl
proc nutation*(tee: float64): float64 =
    ## Return the longitudinal nutation at moment, tee.
    let c = julian_centuries(tee).float64
    let cap_A = poly(c, [mpf(124.90), mpf(-1934.134), mpf(0.002063)])
    let cap_B = poly(c, [mpf(201.11), mpf(72001.5377), mpf(0.00057)])
    return (deg(mpf(-0.004778))  * sin_degrees(cap_A) + 
            deg(mpf(-0.0003667)) * sin_degrees(cap_B))

# see lines 3273-3281 in calendrica-3.0.cl
proc aberration*(tee: float64): float64 =
    ## Return the aberration at moment, tee.
    let c = julian_centuries(tee)
    return ((deg(mpf(0.0000974)) *
             cosine_degrees(deg(mpf(177.63)) + deg(mpf(35999.01848)) * c)) -
            deg(mpf(0.005575)))

# see lines 3283-3295 in calendrica-3.0.cl
proc solar_longitude_after*(lam, tee: float64): float64 =
    ## Return the moment UT of the first time at or after moment, tee,
    ## when the solar longitude will be lam degrees.
    let rate = MEAN_TROPICAL_YEAR / deg(360)
    let tau = tee + rate * modulo(lam - solar_longitude(tee), 360.0)
    let a = max(tee, tau - 5)
    let b = tau + 5
    return invert_angular(solar_longitude, lam, a, b)


# see lines 3317-3339 in calendrica-3.0.cl
proc precession*(tee: float64): float64 =
    ## Return the precession at moment tee using 0,0 as J2000 coordinates.
    ## Adapted from "Astronomical Algorithms" by Jean Meeus,
    ## Willmann-Bell, Inc., 1991.
    let c = julian_centuries(tee)
    let eta = modulo(poly(c, @[0.0,
                             secs(mpf(47.0029)),
                             secs(mpf(-0.03302)),
                             secs(mpf(0.000060))]),
                    360.0)
    let cap_P = modulo(poly(c, [deg(mpf(174.876384)), 
                               secs(mpf(-869.8089)), 
                               secs(mpf(0.03536))]),
                      360.0)
    let p = modulo(poly(c, @[0.0,
                           secs(mpf(5029.0966)),
                           secs(mpf(1.11113)),
                           secs(mpf(0.000006))]),
                  360.0)
    let cap_A = cosine_degrees(eta) * sin_degrees(cap_P)
    let cap_B = cosine_degrees(cap_P)
    let arg = arctan_degrees(cap_A, cap_B)

    return modulo(p + cap_P - arg, 360.0)


# see lines 5207-5211 in calendrica-3.0.cl
const UJJAIN = location(angle(23, 9, 0), angle(75, 46, 6),
                  mt(0), days_from_hours(5 + 461/9000))


# see lines 5213-5216 in calendrica-3.0.cl
# see lines 217-218 in calendrica-3.0.errata.cl
const HINDU_LOCATION = UJJAIN

proc mesha_samkranti*(g_year: int): float64 {.gcsafe.}

# see lines 5489-5493 in calendrica-3.0.cl
var SIDEREAL_START = precession(universal_from_local(mesha_samkranti(ce(285)).float64,
                                                       HINDU_LOCATION))

# see lines 3341-3347 in calendrica-3.0.cl
proc sidereal_solar_longitude*(tee: float64): float64 =
    ## Return sidereal solar longitude at moment, tee.
    return modulo(solar_longitude(tee) - precession(tee) + SIDEREAL_START, 360.0)


# see lines 3349-3365 in calendrica-3.0.cl
proc estimate_prior_solar_longitude*(lam, tee: float64): float64 =
    ## Return approximate moment at or before tee
    ## when solar longitude just exceeded lam degrees.
    let rate = MEAN_TROPICAL_YEAR / deg(360)
    let tau = tee - (rate * modulo(solar_longitude(tee) - lam, 360.0))
    let cap_Delta = modulo(solar_longitude(tau) - lam + deg(180), 360.0) - deg(180)
    return min(tee, tau - (rate * cap_Delta))


# see lines 3367-3376 in calendrica-3.0.cl
proc mean_lunar_longitude*(c: float64): float64 =
    ## Return mean longitude of moon (in degrees) at moment
    ## given in Julian centuries c (including the constant term of the
    ## effect of the light-time (-0".70).
    ## Adapted from eq. 47.1 in "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed. with corrections, 2005.
    return normalized_degrees(poly(c, @[mpf(218.3164477), mpf(481267.88123421),
                               mpf(-0.0015786), mpf(1/538841),
                               mpf(-1/65194000)]))

# see lines 3378-3387 in calendrica-3.0.cl
proc lunar_elongation*(c: float64): float64 =
    ## Return elongation of moon (in degrees) at moment
    ## given in Julian centuries c.
    ## Adapted from eq. 47.2 in "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed. with corrections, 2005.
    return normalized_degrees(poly(c, @[mpf(297.8501921), mpf(445267.1114034),
                                mpf(-0.0018819), mpf(1/545868),
                                mpf(-1/113065000)]))

# see lines 3389-3398 in calendrica-3.0.cl
proc solar_anomaly*(c: float64): float64 =
    ## Return mean anomaly of sun (in degrees) at moment
    ## given in Julian centuries c.
    ## Adapted from eq. 47.3 in "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed. with corrections, 2005.
    return normalized_degrees(poly(c, @[mpf(357.5291092), mpf(35999.0502909),
                               mpf(-0.0001536), mpf(1/24490000)]))

# see lines 3400-3409 in calendrica-3.0.cl
proc lunar_anomaly*(c: float64): float64 =
    ## Return mean anomaly of moon (in degrees) at moment
    ## given in Julian centuries c.
    ## Adapted from eq. 47.4 in "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed. with corrections, 2005.
    return normalized_degrees(poly(c, @[mpf(134.9633964), mpf(477198.8675055),
                                mpf(0.0087414), mpf(1/69699),
                                mpf(-1/14712000)]))


# see lines 3411-3420 in calendrica-3.0.cl
proc moon_node*(c: float64): float64 =
    ## Return Moon's argument of latitude (in degrees) at moment
    ## given in Julian centuries 'c'.
    ## Adapted from eq. 47.5 in "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed. with corrections, 2005.
    return normalized_degrees(poly(c, @[mpf(93.2720950), mpf(483202.0175233),
                                mpf(-0.0036539), mpf(-1/3526000),
                                mpf(1/863310000)]))

# see lines 3422-3485 in calendrica-3.0.cl
proc lunar_longitude*(tee: float64): float64 =
    ## Return longitude of moon (in degrees) at moment tee.
    ## Adapted from "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed., 1998.
    let c = julian_centuries(tee)
    let cap_L_prime = mean_lunar_longitude(c)
    let cap_D = lunar_elongation(c)
    let cap_M = solar_anomaly(c)
    let cap_M_prime = lunar_anomaly(c)
    let cap_F = moon_node(c)
    # see eq. 47.6 in Meeus
    let cap_E = poly(c, @[mpf(1), mpf(-0.002516), mpf(-0.0000074)])
    let args_lunar_elongation = 
            map(@[0, 2, 2, 0, 0, 0, 2, 2, 2, 2, 0, 1, 0, 2, 0, 0, 4, 0, 4, 2, 2, 1,
             1, 2, 2, 4, 2, 0, 2, 2, 1, 2, 0, 0, 2, 2, 2, 4, 0, 3, 2, 4, 0, 2,
             2, 2, 4, 0, 4, 1, 2, 0, 1, 3, 4, 2, 0, 1, 2], mpf)
    let args_solar_anomaly = 
            map(@[0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1,
             0, 1, -1, 0, 0, 0, 1, 0, -1, 0, -2, 1, 2, -2, 0, 0, -1, 0, 0, 1,
             -1, 2, 2, 1, -1, 0, 0, -1, 0, 1, 0, 1, 0, 0, -1, 2, 1, 0], mpf)
    let args_lunar_anomaly = 
            map(@[1, -1, 0, 2, 0, 0, -2, -1, 1, 0, -1, 0, 1, 0, 1, 1, -1, 3, -2,
             -1, 0, -1, 0, 1, 2, 0, -3, -2, -1, -2, 1, 0, 2, 0, -1, 1, 0,
             -1, 2, -1, 1, -2, -1, -1, -2, 0, 1, 4, 0, -2, 0, 2, 1, -2, -3,
             2, 1, -1, 3], mpf)
    let args_moon_node = 
            map(@[0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, -2, 2, -2, 0, 0, 0, 0, 0,
             0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, -2, 2, 0, 2, 0, 0, 0, 0,
             0, 0, -2, 0, 0, 0, 0, -2, -2, 0, 0, 0, 0, 0, 0, 0], mpf)
    let sine_coefficients = 
            map(@[6288774,1274027,658314,213618,-185116,-114332,
             58793,57066,53322,45758,-40923,-34720,-30383,
             15327,-12528,10980,10675,10034,8548,-7888,
             -6766,-5163,4987,4036,3994,3861,3665,-2689,
             -2602, 2390,-2348,2236,-2120,-2069,2048,-1773,
             -1595,1215,-1110,-892,-810,759,-713,-700,691,
             596,549,537,520,-487,-399,-381,351,-340,330,
             327,-323,299,294], mpf)
    let correction = (deg(1/1000000) *
                      sigma(@[sine_coefficients, args_lunar_elongation,
                         args_solar_anomaly, args_lunar_anomaly,
                         args_moon_node],
                         proc(x: seq[float64]):float64 =
                            x[0] * pow(cap_E, abs(x[2])) *
                                       sin_degrees((x[1] * cap_D) +
                                                   (x[2] * cap_M) +
                                                   (x[3] * cap_M_prime) +
                                                   (x[4] * cap_F))))
    let A1 = deg(mpf(119.75)) + (c * deg(mpf(131.849)))
    let venus = (deg(3958/1000000) * sin_degrees(A1))
    let A2 = deg(mpf(53.09)) + c * deg(mpf(479264.29))
    let jupiter = (deg(318/1000000) * sin_degrees(A2))
    let flat_earth = (deg(1962/1000000) * sin_degrees(cap_L_prime - cap_F))

    return modulo(cap_L_prime + correction + venus +
                 jupiter + flat_earth + nutation(tee), 360.0)

# see lines 3663-3732 in calendrica-3.0.cl
proc lunar_latitude*(tee: float64): float64 =
    ## Return the latitude of moon (in degrees) at moment, tee.
    ## Adapted from "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 1998.
    let c = julian_centuries(tee)
    let cap_L_prime = mean_lunar_longitude(c)
    let cap_D = lunar_elongation(c)
    let cap_M = solar_anomaly(c)
    let cap_M_prime = lunar_anomaly(c)
    let cap_F = moon_node(c)
    let cap_E = poly(c, @[1.0, mpf(-0.002516), mpf(-0.0000074)])
    let args_lunar_elongation = 
            map(@[0, 0, 0, 2, 2, 2, 2, 0, 2, 0, 2, 2, 2, 2, 2, 2, 2, 0, 4, 0, 0, 0,
             1, 0, 0, 0, 1, 0, 4, 4, 0, 4, 2, 2, 2, 2, 0, 2, 2, 2, 2, 4, 2, 2,
             0, 2, 1, 1, 0, 2, 1, 2, 0, 4, 4, 1, 4, 1, 4, 2], mpf)
    let args_solar_anomaly = 
            map(@[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, -1, -1, -1, 1, 0, 1,
             0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 1,
             0, -1, -2, 0, 1, 1, 1, 1, 1, 0, -1, 1, 0, -1, 0, 0, 0, -1, -2], mpf)
    let args_lunar_anomaly = 
            map(@[0, 1, 1, 0, -1, -1, 0, 2, 1, 2, 0, -2, 1, 0, -1, 0, -1, -1, -1,
             0, 0, -1, 0, 1, 1, 0, 0, 3, 0, -1, 1, -2, 0, 2, 1, -2, 3, 2, -3,
             -1, 0, 0, 1, 0, 1, 1, 0, 0, -2, -1, 1, -2, 2, -2, -1, 1, 1, -2,
             0, 0], mpf)
    let args_moon_node = 
            map(@[1, 1, -1, -1, 1, -1, 1, 1, -1, -1, -1, -1, 1, -1, 1, 1, -1, -1,
             -1, 1, 3, 1, 1, 1, -1, -1, -1, 1, -1, 1, -3, 1, -3, -1, -1, 1,
             -1, 1, -1, 1, 1, 1, 1, -1, 3, -1, -1, 1, -1, -1, 1, -1, 1, -1,
             -1, -1, -1, -1, -1, 1], mpf)
    let sine_coefficients = 
            map(@[5128122, 280602, 277693, 173237, 55413, 46271, 32573,
             17198, 9266, 8822, 8216, 4324, 4200, -3359, 2463, 2211,
             2065, -1870, 1828, -1794, -1749, -1565, -1491, -1475,
             -1410, -1344, -1335, 1107, 1021, 833, 777, 671, 607,
             596, 491, -451, 439, 422, 421, -366, -351, 331, 315,
             302, -283, -229, 223, 223, -220, -220, -185, 181,
             -177, 176, 166, -164, 132, -119, 115, 107], mpf)
    let beta = (deg(1.0/1000000.0) *
                sigma(@[sine_coefficients, 
                   args_lunar_elongation,
                   args_solar_anomaly,
                   args_lunar_anomaly,
                   args_moon_node],
                   proc(x: seq[float64]):float64 = 
                        x[0] * pow(cap_E, abs(x[2])) *
                                    sin_degrees((x[1] * cap_D) +
                                                (x[2] * cap_M) +
                                                (x[3] * cap_M_prime) +
                                                (x[4] * cap_F))))
    let venus = (deg(175.0/1000000.0) *
             (sin_degrees(deg(mpf(119.75)) + c * deg(mpf(131.849)) + cap_F) +
              sin_degrees(deg(mpf(119.75)) + c * deg(mpf(131.849)) - cap_F)))
    let flat_earth = (deg(-2235.0/1000000.0) *  sin_degrees(cap_L_prime) +
                  deg(127.0/1000000.0) * sin_degrees(cap_L_prime - cap_M_prime) +
                  deg(-115.0/1000000.0) * sin_degrees(cap_L_prime + cap_M_prime))
    let extra = (deg(382.0/1000000.0) *
             sin_degrees(deg(mpf(313.45)) + c * deg(mpf(481266.484))))
    return beta + venus + flat_earth + extra


# see lines 192-197 in calendrica-3.0.errata.cl
proc lunar_node*(tee: float64): float64 =
    ## Return Angular distance of the node from the equinoctal point
    ## at fixed moment, tee.
    ## Adapted from eq. 47.7 in "Astronomical Algorithms"
    ## by Jean Meeus, Willmann_Bell, Inc., 2nd ed., 1998
    ## with corrections June 2005.
    return modulo(moon_node(julian_centuries(tee)) + deg(90), 180.0) - 90

proc alt_lunar_node*(tee: float64): float64 =
    ## Return Angular distance of the node from the equinoctal point
    ## at fixed moment, tee.
    ## Adapted from eq. 47.7 in "Astronomical Algorithms"
    ## by Jean Meeus, Willmann_Bell, Inc., 2nd ed., 1998
    ## with corrections June 2005.
    return normalized_degrees(poly(julian_centuries(tee), 
                                   [mpf(125.0445479),
                                    mpf(-1934.1362891),
                                    mpf(0.0020754),
                                    mpf(1/467441),
                                    mpf(-1/60616000)]))

proc lunar_true_node*(tee: float64): float64 =
    ## Return Angular distance of the true node (the node of the instantaneus
    ## lunar orbit) from the equinoctal point at moment, tee.
    ## Adapted from eq. 47.7 and pag. 344 in "Astronomical Algorithms"
    ## by Jean Meeus, Willmann_Bell, Inc., 2nd ed., 1998
    ## with corrections June 2005.
    let c = julian_centuries(tee)
    let cap_D = lunar_elongation(c)
    let cap_M = solar_anomaly(c)
    let cap_M_prime = lunar_anomaly(c)
    let cap_F = moon_node(c)
    let periodic_terms = (deg(-1.4979) * sin_degrees(2 * (cap_D - cap_F)) +
                          deg(-0.1500) * sin_degrees(cap_M) +
                          deg(-0.1226) * sin_degrees(2 * cap_D) +
                          deg(0.1176)  * sin_degrees(2 * cap_F) +
                          deg(-0.0801) * sin_degrees(2 * (cap_M_prime - cap_F)))
    return alt_lunar_node(tee) + periodic_terms

proc lunar_perigee*(tee: float64): float64 =
    ## Return Angular distance of the perigee from the equinoctal point
    ## at moment, tee.
    ## Adapted from eq. 47.7 in "Astronomical Algorithms"
    ## by Jean Meeus, Willmann_Bell, Inc., 2nd ed., 1998
    ## with corrections June 2005.
    return normalized_degrees(poly(julian_centuries(tee), [mpf(83.3532465),
                                                     mpf(4069.0137287),
                                                     mpf(-0.0103200),
                                                     mpf(-1/80053),
                                                     mpf(1/18999000)]))


# see lines 199-206 in calendrica-3.0.errata.cl
proc sidereal_lunar_longitude*(tee: float64): float64 =
    ## Return sidereal lunar longitude at moment, tee.
    return modulo(lunar_longitude(tee) - precession(tee) + SIDEREAL_START, 360.0)


# see lines 99-190 in calendrica-3.0.errata.cl
proc nth_new_moon*(n: float64): float64 = 
    ## Return the moment of n-th new moon after (or before) the new moon
    ## of January 11, 1.  Adapted from "Astronomical Algorithms"
    ## by Jean Meeus, Willmann_Bell, Inc., 2nd ed., 1998.
    let n0 = 24724.float64
    let k = n - n0
    let c = k / mpf(1236.85)
    let approx = (J2000 +
                 poly(c, [mpf(5.09766),
                          MEAN_SYNODIC_MONTH * mpf(1236.85),
                          mpf(0.0001437),
                          mpf(-0.000000150),
                          mpf(0.00000000073)]))
    let cap_E = poly(c, @[1.0, mpf(-0.002516), mpf(-0.0000074)])
    let solar_anomaly = poly(c, @[mpf(2.5534),
                                 (mpf(1236.85) * mpf(29.10535669)),
                                 mpf(-0.0000014), mpf(-0.00000011)])
    let lunar_anomaly = poly(c, @[mpf(201.5643),
                                 (mpf(385.81693528) * mpf(1236.85)),
                                 mpf(0.0107582), mpf(0.00001238),
                                 mpf(-0.000000058)])
    let moon_argument = poly(c, @[mpf(160.7108),
                                 (mpf(390.67050284) * mpf(1236.85)),
                                 mpf(-0.0016118), mpf(-0.00000227),
                                 mpf(0.000000011)])
    let cap_omega = poly(c, @[mpf(124.7746),
                            (mpf(-1.56375588) * mpf(1236.85)),
                            mpf(0.0020672), mpf(0.00000215)])
    let E_factor = map(@[0, 1, 0, 0, 1, 1, 2, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0,
                    0, 0, 0, 0, 0, 0], mpf)
    let solar_coeff = map(@[0, 1, 0, 0, -1, 1, 2, 0, 0, 1, 0, 1, 1, -1, 2,
                        0, 3, 1, 0, 1, -1, -1, 1, 0], mpf)
    let lunar_coeff = map(@[1, 0, 2, 0, 1, 1, 0, 1, 1, 2, 3, 0, 0, 2, 1, 2,
                        0, 1, 2, 1, 1, 1, 3, 4], mpf)
    let moon_coeff = map(@[0, 0, 0, 2, 0, 0, 0, -2, 2, 0, 0, 2, -2, 0, 0,
                       -2, 0, -2, 2, 2, 2, -2, 0, 0], mpf)
    let sine_coeff = @[mpf(-0.40720), mpf(0.17241), mpf(0.01608),
                       mpf(0.01039),  mpf(0.00739), mpf(-0.00514),
                       mpf(0.00208), mpf(-0.00111), mpf(-0.00057),
                       mpf(0.00056), mpf(-0.00042), mpf(0.00042),
                       mpf(0.00038), mpf(-0.00024), mpf(-0.00007),
                       mpf(0.00004), mpf(0.00004), mpf(0.00003),
                       mpf(0.00003), mpf(-0.00003), mpf(0.00003),
                       mpf(-0.00002), mpf(-0.00002), mpf(0.00002)]
    let correction = ((deg(mpf(-0.00017)) * sin_degrees(cap_omega)) +
                      sigma(@[sine_coeff, E_factor, solar_coeff,
                             lunar_coeff, moon_coeff],
                        proc(x:seq[float64]):float64 = 
                            x[0] * pow(cap_E, x[1]) *
                                    sin_degrees((x[2] * solar_anomaly) + 
                                                (x[3] * lunar_anomaly) +
                                                (x[4] * moon_argument))))
    let add_const = @[mpf(251.88), mpf(251.83), mpf(349.42), mpf(84.66),
                      mpf(141.74), mpf(207.14), mpf(154.84), mpf(34.52),
                      mpf(207.19), mpf(291.34), mpf(161.72), mpf(239.56),
                      mpf(331.55)]
    let add_coeff = @[mpf(0.016321), mpf(26.651886), mpf(36.412478),
                     mpf(18.206239), mpf(53.303771), mpf(2.453732),
                     mpf(7.306860), mpf(27.261239), mpf(0.121824),
                     mpf(1.844379), mpf(24.198154), mpf(25.513099),
                     mpf(3.592518)]
    let add_factor = @[mpf(0.000165), mpf(0.000164), mpf(0.000126),
                      mpf(0.000110), mpf(0.000062), mpf(0.000060),
                      mpf(0.000056), mpf(0.000047), mpf(0.000042),
                      mpf(0.000040), mpf(0.000037), mpf(0.000035),
                      mpf(0.000023)]
    let extra = (deg(mpf(0.000325)) *
                 sin_degrees(poly(c, @[mpf(299.77), mpf(132.8475848),
                                       mpf(-0.009173)])))
    let additional = sigma(@[add_const, add_coeff, add_factor],
                       proc(x:seq[float64]):float64 =  
                        x[2] * sin_degrees(x[0] + x[1] * k))

    return universal_from_dynamical(approx + correction + extra + additional)


# see lines 3578-3585 in calendrica-3.0.cl
proc new_moon_before*(tee: float64): float64 =
    ## Return the moment UT of last new moon before moment tee.
    let t0 = nth_new_moon(0.0)
    let phi = lunar_phase(tee)
    let n = iround(((tee - t0) / MEAN_SYNODIC_MONTH) - (phi / deg(360)))
    return nth_new_moon(final(n - 1, proc(k: int):bool = nth_new_moon(k.float64) < tee).float64)


# see lines 3587-3594 in calendrica-3.0.cl
proc new_moon_at_or_after*(tee: float64): float64 = 
    ## Return the moment UT of first new moon at or after moment, tee.
    let t0 = nth_new_moon(0.0)
    let phi = lunar_phase(tee)
    let n = iround((tee - t0) / MEAN_SYNODIC_MONTH - phi / deg(360))
    return nth_new_moon(next(n, proc(k:int):bool = nth_new_moon(k.float64) >= tee).float64)


# see lines 3596-3613 in calendrica-3.0.cl
proc lunar_phase*(tee: float64): float64 =
    ## Return the lunar phase, as an angle in degrees, at moment tee.
    ## An angle of 0 means a new moon, 90 degrees means the
    ## first quarter, 180 means a full moon, and 270 degrees
    ## means the last quarter.
    let phi = modulo(lunar_longitude(tee) - solar_longitude(tee), 360.0)
    let t0 = nth_new_moon(0.0)
    let n = round((tee - t0) / MEAN_SYNODIC_MONTH)
    let phi_prime = (deg(360.0) *
                     modulo((tee - nth_new_moon(n)) / MEAN_SYNODIC_MONTH, 1.0))
    if abs(phi - phi_prime) > deg(180.0):
        return phi_prime
    else:
        return phi


# see lines 3615-3625 in calendrica-3.0.cl
proc lunar_phase_at_or_before*(phi, tee: float64): float64 =
    ## Return the moment UT of the last time at or before moment, tee,
    ## when the lunar_phase was phi degrees.
    let tau = (tee -
              (MEAN_SYNODIC_MONTH  *
              (1/deg(360)) *
              modulo(lunar_phase(tee) - phi, 360.0)))
    let a = tau - 2
    let b = min(tee, tau + 2)
    return invert_angular(lunar_phase, phi, a, b)


# see lines 3627-3631 in calendrica-3.0.cl
const NEW = deg(0)

# see lines 3633-3637 in calendrica-3.0.cl
const FIRST_QUARTER = deg(90)

# see lines 3639-3643 in calendrica-3.0.cl
const FULL = deg(180)

# see lines 3645-3649 in calendrica-3.0.cl
const LAST_QUARTER = deg(270)

# see lines 3651-3661 in calendrica-3.0.cl
proc lunar_phase_at_or_after*(phi, tee: float64): float64 =
    ## Return the moment UT of the next time at or after moment, tee,
    ## when the lunar_phase is phi degrees.
    let tau = (tee +
              (MEAN_SYNODIC_MONTH *
              (1.0/deg(360.0)) *
              modulo(phi - lunar_phase(tee), 360.0)))
    let a = max(tee, tau - 2.0)
    let b = tau + 2.0
    return invert_angular(lunar_phase, phi, a, b)


# see lines 3734-3762 in calendrica-3.0.cl
proc lunar_altitude*(tee: float64, location: calLocationData): float64 =
    ## Return the geocentric altitude of moon at moment, tee,
    ## at location, location, as a small positive/negative angle in degrees,
    ## ignoring parallax and refraction.  Adapted from 'Astronomical
    ## Algorithms' by Jean Meeus, Willmann_Bell, Inc., 1998.
    let phi = latitude(location)
    let psi = longitude(location)
    let lamb = lunar_longitude(tee)
    let beta = lunar_latitude(tee)
    let alpha = right_ascension(tee, beta, lamb)
    let delta = declination(tee, beta, lamb)
    let theta0 = sidereal_from_moment(tee)
    let cap_H = modulo(theta0 + psi - alpha, 360.0)
    let altitude = arcsin_degrees(
        (sin_degrees(phi) * sin_degrees(delta)) +
        (cosine_degrees(phi) * cosine_degrees(delta) * cosine_degrees(cap_H)))
    return modulo(altitude + deg(180), 360.0) - deg(180)
 

# see lines 3764-3813 in calendrica-3.0.cl
proc lunar_distance*(tee:float64): float64 =
    ## Return the distance to moon (in meters) at moment, tee.
    ## Adapted from "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed.
    let c = julian_centuries(tee)
    let cap_D = lunar_elongation(c)
    let cap_M = solar_anomaly(c)
    let cap_M_prime = lunar_anomaly(c)
    let cap_F = moon_node(c)
    let cap_E = poly(c, [1.0, mpf(-0.002516), mpf(-0.0000074)])
    let args_lunar_elongation = 
        map(@[0, 2, 2, 0, 0, 0, 2, 2, 2, 2, 0, 1, 0, 2, 0, 0, 4, 0, 4, 2, 2, 1,
         1, 2, 2, 4, 2, 0, 2, 2, 1, 2, 0, 0, 2, 2, 2, 4, 0, 3, 2, 4, 0, 2,
         2, 2, 4, 0, 4, 1, 2, 0, 1, 3, 4, 2, 0, 1, 2, 2,], mpf)
    let args_solar_anomaly = 
        map(@[0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1,
         0, 1, -1, 0, 0, 0, 1, 0, -1, 0, -2, 1, 2, -2, 0, 0, -1, 0, 0, 1,
         -1, 2, 2, 1, -1, 0, 0, -1, 0, 1, 0, 1, 0, 0, -1, 2, 1, 0, 0], mpf)
    let args_lunar_anomaly = 
        map(@[1, -1, 0, 2, 0, 0, -2, -1, 1, 0, -1, 0, 1, 0, 1, 1, -1, 3, -2,
         -1, 0, -1, 0, 1, 2, 0, -3, -2, -1, -2, 1, 0, 2, 0, -1, 1, 0,
         -1, 2, -1, 1, -2, -1, -1, -2, 0, 1, 4, 0, -2, 0, 2, 1, -2, -3,
         2, 1, -1, 3, -1], mpf)
    let args_moon_node = 
        map(@[0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, -2, 2, -2, 0, 0, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, -2, 2, 0, 2, 0, 0, 0, 0,
         0, 0, -2, 0, 0, 0, 0, -2, -2, 0, 0, 0, 0, 0, 0, 0, -2], mpf)
    let cosine_coefficients = 
        map(@[-20905355, -3699111, -2955968, -569925, 48888, -3149,
         246158, -152138, -170733, -204586, -129620, 108743,
         104755, 10321, 0, 79661, -34782, -23210, -21636, 24208,
         30824, -8379, -16675, -12831, -10445, -11650, 14403,
         -7003, 0, 10056, 6322, -9884, 5751, 0, -4950, 4130, 0,
         -3958, 0, 3258, 2616, -1897, -2117, 2354, 0, 0, -1423,
         -1117, -1571, -1739, 0, -4421, 0, 0, 0, 0, 1165, 0, 0,
         8752], mpf)
    let correction = sigma(@[cosine_coefficients,
                              args_lunar_elongation,
                              args_solar_anomaly,
                              args_lunar_anomaly,
                              args_moon_node],
                            proc(x: seq[float64]): float64 =
                                x[0] * pow(cap_E, abs(x[2])) * 
                                 cosine_degrees((x[1] * cap_D) +
                                                (x[2] * cap_M) +
                                                (x[3] * cap_M_prime) +
                                                (x[4] * cap_F)))
    return mt(385000560) + correction


proc lunar_position*(tee: float64): (float64, float64, float64) =
    ## Return the moon position (geocentric latitude and longitude [in degrees]
    ## and distance [in meters]) at moment, tee.
    ## Adapted from "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 2nd ed.
    return (lunar_latitude(tee), lunar_longitude(tee), lunar_distance(tee))

# see lines 3815-3824 in calendrica-3.0.cl
proc lunar_parallax*(tee: float64, location: calLocationData): float64 =
    ## Return the parallax of moon at moment, tee, at location, location.
    ## Adapted from "Astronomical Algorithms" by Jean Meeus,
    ## Willmann_Bell, Inc., 1998.
    let geo = lunar_altitude(tee, location)
    let Delta = lunar_distance(tee)
    let alt = mt(6378140) / Delta
    let arg = alt * cosine_degrees(geo)
    return arcsin_degrees(arg)


# see lines 3826-3832 in calendrica-3.0.cl
proc topocentric_lunar_altitude*(tee: float64, location: calLocationData): float64 =
    ## Return the topocentric altitude of moon at moment, tee,
    ## at location, location, as a small positive/negative angle in degrees,
    ## ignoring refraction.
    return lunar_altitude(tee, location) - lunar_parallax(tee, location)


# see lines 3834-3839 in calendrica-3.0.cl
proc lunar_diameter*(tee: float64): float64 =
    ## Return the geocentric apparent lunar diameter of the moon (in
    ## degrees) at moment, tee.  Adapted from 'Astronomical
    ## Algorithms' by Jean Meeus, Willmann_Bell, Inc., 2nd ed.
    return deg(1792367000/9) / lunar_distance(tee)


############################################
## astronomical lunar calendars algorithms #
############################################

# see lines 5829-5845 in calendrica-3.0.cl
proc visible_crescent*(date: float64, location: calLocationData): bool =
    ## Return S. K. Shaukat's criterion for likely
    ## visibility of crescent moon on eve of date 'date',
    ## at location 'location'.
    let tee = universal_from_standard(dusk(date - 1, location, deg(mpf(4.5))),
                                      location)
    let phase = lunar_phase(tee)
    let altitude = lunar_altitude(tee, location)
    let arc_of_light = arccos_degrees(cosine_degrees(lunar_latitude(tee)) *
                                      cosine_degrees(phase))
    return ((phase > NEW and phase < FIRST_QUARTER) and
            (arc_of_light >= deg(mpf(10.6)) and arc_of_light <= deg(90)) and
            (altitude > deg(mpf(4.1))))


# see lines 5847-5860 in calendrica-3.0.cl
proc phasis_on_or_before*(date: int, location: calLocationData): int =
    ## Return the closest fixed date on or before date 'date', when crescent
    ## moon first became visible at location 'location'.
    let mean = date - ifloor(lunar_phase((date + 1).float64) / deg(360) *
                             MEAN_SYNODIC_MONTH)
    var tau: int 
    if date - mean <= 3 and not visible_crescent(date.float64, location):
        tau = mean - 30
    else:
        tau = mean - 2

    result = next(tau, proc(d:int):bool = visible_crescent(d.float64, location))


# see lines 5862-5866 in calendrica-3.0.cl
# see lines 220-221 in calendrica-3.0.errata.cl
# Sample location for Observational Islamic calendar
# (Cairo, Egypt).
const ISLAMIC_LOCATION = location(deg(mpf(30.1)), deg(mpf(31.3)), mt(200), days_from_hours(2))


# see lines 5868-5882 in calendrica-3.0.cl
proc fixed_from_observational_islamic*(i_date: calDate): int =
    ## Return fixed date equivalent to Observational Islamic date, i_date.
    let month    = standard_month(i_date)
    let day      = standard_day(i_date)
    let year     = standard_year(i_date)
    let midmonth = ISLAMIC_EPOCH + ifloor((((year - 1) * 12).float64 + month.float64 - 0.5) *
                                          MEAN_SYNODIC_MONTH)
    return (phasis_on_or_before(midmonth, ISLAMIC_LOCATION) +
            day - 1)


# see lines 5884-5896 in calendrica-3.0.cl
proc observational_islamic_from_fixed*(date: int): calDate =
    ## Return Observational Islamic date (year month day)
    ## corresponding to fixed date, date.
    let crescent = phasis_on_or_before(date, ISLAMIC_LOCATION)
    let elapsed_months = iround((crescent - ISLAMIC_EPOCH).float64 / MEAN_SYNODIC_MONTH)
    let year = quotient(elapsed_months, 12) + 1
    let month = modulo(elapsed_months, 12) + 1
    let day = (date - crescent) + 1
    return islamic_date(year, month, day)

# # see lines 5898-5901 in calendrica-3.0.cl
# const JERUSALEM = location(deg(mpf(31.8)), deg(mpf(35.2)), mt(800), days_from_hours(2))

# see lines 5903-5918 in calendrica-3.0.cl
proc astronomical_easter*(g_year: int): int =
    ## Return date of (proposed) astronomical Easter in Gregorian
    ## year, g_year.
    let jan1 = gregorian_new_year(g_year)
    let equinox = solar_longitude_after(SPRING, jan1.float)
    let paschal_moon = ifloor(apparent_from_local(
                                 local_from_universal(
                                    lunar_phase_at_or_after(FULL, equinox),
                                    JERUSALEM),
                                 JERUSALEM))
    # Return the Sunday following the Paschal moon.
    return kday_after(SUNDAY, paschal_moon)

# see lines 5920-5923 in calendrica-3.0.cl
const JAFFA = location(angle(32, 1, 60), angle(34, 45, 0), mt(0), days_from_hours(2))

# see lines 5925-5938 in calendrica-3.0.cl
proc phasis_on_or_after*(date: int, location: calLocationData): int = 
    ## Return closest fixed date on or after date, date, on the eve
    ## of which crescent moon first became visible at location, location.
    let mean = date - ifloor(lunar_phase((date + 1).float64) / deg(mpf(360)) *
                             MEAN_SYNODIC_MONTH)
    var tau: int
    if date - mean <= 3 and not visible_crescent((date - 1).float64, location):
        tau = date
    else:
        tau = mean + 29
    return next(tau, proc(d:int):bool =  visible_crescent(d.float64, location))


# see lines 5940-5955 in calendrica-3.0.cl
proc observational_hebrew_new_year*(g_year: int): int =
    ## Return fixed date of Observational (classical)
    ## Nisan 1 occurring in Gregorian year, g_year.
    let jan1 = gregorian_new_year(g_year)
    let equinox = solar_longitude_after(SPRING, jan1.float64)
    let sset = universal_from_standard(sunset(ifloor(equinox).float64, JAFFA), JAFFA)
    return phasis_on_or_after(ifloor(equinox) - (if (equinox < sset): 14 else: 13),
                              JAFFA)


# see lines 5957-5973 in calendrica-3.0.cl
proc fixed_from_observational_hebrew*(h_date: calDate): int =
    ## Return fixed date equivalent to Observational Hebrew date.
    let month = standard_month(h_date)
    let day = standard_day(h_date)
    let year = standard_year(h_date)
    let year1 = if (month >= TISHRI): year - 1 else: year
    let start = fixed_from_hebrew(hebrew_date(year1, NISAN, 1))
    let g_year = gregorian_year_from_fixed(start + 60)
    let new_year = observational_hebrew_new_year(g_year)
    let midmonth = new_year + iround(29.5 * (month - 1).float64) + 15
    return phasis_on_or_before(midmonth, JAFFA) + day - 1


# see lines 5975-5991 in calendrica-3.0.cl
proc observational_hebrew_from_fixed*(date: int): calDate =
    ## Return Observational Hebrew date (year month day)
    ## corresponding to fixed date, date.
    let crescent = phasis_on_or_before(date, JAFFA)
    let g_year = gregorian_year_from_fixed(date)
    let ny = observational_hebrew_new_year(g_year)
    let new_year = if (date < ny): observational_hebrew_new_year(g_year - 1) else: ny
    let month = iround((crescent - new_year).float64 / 29.5) + 1
    let year = (standard_year(hebrew_from_fixed(new_year)) +
               (if (month >= TISHRI): 1 else: 0))
    let day = date - crescent + 1
    return hebrew_date(year, month, day)


# see lines 5993-5997 in calendrica-3.0.cl
proc classical_passover_eve(g_year: int): int =
    ## Return fixed date of Classical (observational) Passover Eve
    ## (Nisan 14) occurring in Gregorian year, g_year.
    return observational_hebrew_new_year(g_year) + 13


################################
## persian calendar algorithms #
################################

# see lines 3844-3847 in calendrica-3.0.cl
proc persian_date*(year, month, day: int): calDate =
    ## Return a Persian date data structure.
    return calDate(year: year, month: month, day: day)

# see lines 3849-3852 in calendrica-3.0.cl
const PERSIAN_EPOCH = fixed_from_julian(julian_date(ce(622), MARCH, 19))

# see lines 3854-3858 in calendrica-3.0.cl
const TEHRAN = location(deg(mpf(35.68)),
                        deg(mpf(51.42)),
                        mt(1100),
                        days_from_hours(3 + 1/2))

# see lines 3860-3865 in calendrica-3.0.cl
proc midday_in_tehran*(date: int): float64 =
    ## Return  Universal time of midday on fixed date, date, in Tehran.
    return universal_from_standard(midday(date.float64, TEHRAN), TEHRAN)

# see lines 3867-3876 in calendrica-3.0.cl
proc persian_new_year_on_or_before*(date: int): int =
    ## Return the fixed date of Astronomical Persian New Year on or
    ## before fixed date, date.
    let approx = estimate_prior_solar_longitude(SPRING, midday_in_tehran(date))
    return next(ifloor(approx) - 1,
                proc(day:int):bool = 
                    (solar_longitude(midday_in_tehran(day)) <= (SPRING + deg(2))))

# see lines 3880-3898 in calendrica-3.0.cl
proc fixed_from_persian*(p_date: calDate): int =
    ## Return fixed date of Astronomical Persian date, p_date.
    let month = standard_month(p_date)
    let day = standard_day(p_date)
    let year = standard_year(p_date)
    let temp = if (0 < year): (year - 1) else: year
    let new_year = persian_new_year_on_or_before(PERSIAN_EPOCH + 180 +
                                                 ifloor(MEAN_TROPICAL_YEAR * temp.float64))
    return ((new_year - 1) +
            (if (month <= 7): (31 * (month - 1))  else: (30 * (month - 1) + 6)) + day)

# see lines 3898-3918 in calendrica-3.0.cl
proc persian_from_fixed*(date: int): calDate =
    ## Return Astronomical Persian date (year month day)
    ## corresponding to fixed date, date.
    let new_year = persian_new_year_on_or_before(date)
    let y = iround((new_year - PERSIAN_EPOCH).float64 / MEAN_TROPICAL_YEAR) + 1
    let year = if 0 < y: y else: y - 1
    let day_of_year = date - fixed_from_persian(persian_date(year, 1, 1)) + 1
    let month = if day_of_year <= 186: 
                    ceiling(day_of_year / 31)
                else:
                    ceiling((day_of_year - 6) / 30)
    let day = date - (fixed_from_persian(persian_date(year, month, 1)) - 1)
    return persian_date(year, month, day)

# see lines 3920-3932 in calendrica-3.0.cl
proc is_arithmetic_persian_leap_year*(p_year: int): bool =
    ## Return True if p_year is a leap year on the Persian calendar.
    let y    = if 0 < p_year: p_year - 474 else: p_year - 473
    let year =  modulo(y, 2820) + 474
    return  modulo((year + 38) * 31, 128) < 31

# see lines 3934-3958 in calendrica-3.0.cl
proc fixed_from_arithmetic_persian*(p_date: calDate): int =
    ## Return fixed date equivalent to Persian date p_date.
    let day    = standard_day(p_date)
    let month  = standard_month(p_date)
    let p_year = standard_year(p_date)
    let y      = if 0 < p_year: p_year - 474 else: p_year - 473
    let year   = modulo(y, 2820) + 474
    let temp   = if month <= 7: (31 * (month - 1)) else: ((30 * (month - 1)) + 6)

    return ((PERSIAN_EPOCH - 1) +
            (1029983 * quotient(y, 2820)) +
            (365 * (year - 1)) +
            quotient((31 * year) - 5, 128) +
            temp +
            day)

# see lines 3960-3986 in calendrica-3.0.cl
proc arithmetic_persian_year_from_fixed*(date: int): int =
    ## Return Persian year corresponding to the fixed date, date.
    let d0    = date - fixed_from_arithmetic_persian(persian_date(475, 1, 1))
    let n2820 = quotient(d0, 1029983)
    let d1    = modulo(d0, 1029983)
    let y2820 = if d1 == 1029982: 2820 else: quotient((128 * d1) + 46878, 46751)
    let year  = 474 + (2820 * n2820) + y2820

    return if 0 < year: year else: year - 1

# see lines 3988-4001 in calendrica-3.0.cl
proc arithmetic_persian_from_fixed*(date: int ): calDate =
    ## Return the Persian date corresponding to fixed date, date.
    let year = arithmetic_persian_year_from_fixed(date)
    let day_of_year = 1 + date - fixed_from_arithmetic_persian(
                                    persian_date(year, 1, 1))
    let month = if day_of_year <= 186: 
                    ceiling(day_of_year / 31)
                else: 
                    ceiling((day_of_year - 6) / 30)

    let day = date - fixed_from_arithmetic_persian(persian_date(year, month, 1)) + 1
    return persian_date(year, month, day)

# see lines 4003-4015 in calendrica-3.0.cl
proc naw_ruz*(g_year: int): int =
    ## Return the Fixed date of Persian New Year (Naw-Ruz) in Gregorian
    ## year g_year.
    let persian_year = g_year - gregorian_year_from_fixed(PERSIAN_EPOCH) + 1
    let y = if persian_year <= 0: persian_year - 1 else: persian_year
    return fixed_from_persian(persian_date(y, 1, 1))


# #############################
# # bahai calendar algorithms #
# #############################

type calBahDate = object
    major: int
    cycle: int
    year: int
    month: int
    day: int

# see lines 4020-4023 in calendrica-3.0.cl
proc bahai_date*(major, cycle, year, month, day: int): calBahDate =
    ## Return a Bahai date data structure.
    return calBahDate(major: major, cycle: cycle, year: year, month: month, day: day)

# see lines 4025-4027 in calendrica-3.0.cl
proc bahai_major*(date: calBahDate): int =
    ### Return 'major' element of a  Bahai date, date.
    return date.major

# see lines 4029-4031 in calendrica-3.0.cl
proc bahai_cycle*(date: calBahDate): int =
    ### Return 'cycle' element of a  Bahai date, date.
    return date.cycle

# see lines 4033-4035 in calendrica-3.0.cl
proc bahai_year(date: calBahDate): int =
    ## Return 'year' element of a  Bahai date, date.
    return date.year

# see lines 4037-4039 in calendrica-3.0.cl
proc bahai_month(date: calBahDate): int =
    ## Return 'month' element of a  Bahai date, date.
    return date.month

# see lines 4041-4043 in calendrica-3.0.cl
proc bahai_day(date: calBahDate): int =
    ## Return 'day' element of a  Bahai date, date.
    return date.day

# see lines 4045-4048 in calendrica-3.0.cl
const BAHAI_EPOCH = fixed_from_gregorian(gregorian_date(1844, MARCH, 21))

# see lines 4050-4053 in calendrica-3.0.cl
const AYYAM_I_HA = 0

# see lines 4055-4076 in calendrica-3.0.cl
proc fixed_from_bahai(b_date: calBahDate): int =
    ## Return fixed date equivalent to the Bahai date, b_date.
    let major = bahai_major(b_date)
    let cycle = bahai_cycle(b_date)
    let year  = bahai_year(b_date)
    let month = bahai_month(b_date)
    let day   = bahai_day(b_date)
    let g_year = (361 * (major - 1) +
                  19 * (cycle - 1)  +
                  year - 1 +
                  gregorian_year_from_fixed(BAHAI_EPOCH))

    var elapsed_months: int
    if (month == AYYAM_I_HA):
        elapsed_months = 342
    elif (month == 19):
        if (is_gregorian_leap_year(g_year + 1)):
            elapsed_months = 347
        else:
            elapsed_months = 346
    else:
        elapsed_months = 19 * (month - 1)

    return (fixed_from_gregorian(gregorian_date(g_year, MARCH, 20)) +
            elapsed_months +
            day)

# see lines 4078-4111 in calendrica-3.0.cl
proc bahai_from_fixed(date: int): calBahDate =
    ## Return Bahai date [major, cycle, year, month, day] corresponding
    ## to fixed date, date.
    let g_year = gregorian_year_from_fixed(date)
    let start  = gregorian_year_from_fixed(BAHAI_EPOCH)
    let years  = (g_year - start -
                 (if (date <= fixed_from_gregorian(
                     gregorian_date(g_year, MARCH, 20))): 1 else: 0))
    let major  = 1 + quotient(years, 361)
    let cycle  = 1 + quotient(modulo(years, 361), 19)
    let year   = 1 + modulo(years, 19)
    let days   = date - fixed_from_bahai(bahai_date(major, cycle, year, 1, 1))

    var month: int
    if (date >= fixed_from_bahai(bahai_date(major, cycle, year, 19, 1))):
        month = 19
    elif (date >= fixed_from_bahai(
        bahai_date(major, cycle, year, AYYAM_I_HA, 1))):
        month = AYYAM_I_HA
    else:
        month = 1 + quotient(days, 19)

    let day = date + 1 - fixed_from_bahai(bahai_date(major, cycle, year, month, 1))

    return bahai_date(major, cycle, year, month, day)


# see lines 4113-4117 in calendrica-3.0.cl
proc bahai_new_year(g_year: int): int =
    ## Return fixed date of Bahai New Year in Gregorian year, g_year.
    return fixed_from_gregorian(gregorian_date(g_year, MARCH, 21))

# see lines 4119-4122 in calendrica-3.0.cl
const HAIFA = location(deg(mpf(32.82)), deg(35), mt(0), days_from_hours(2))


# see lines 4124-4130 in calendrica-3.0.cl
proc sunset_in_haifa(date: int): float64 =
    ## Return universal time of sunset of evening
    ## before fixed date, date in Haifa.
    return universal_from_standard(sunset(date.float64, HAIFA), HAIFA)

# see lines 4132-4141 in calendrica-3.0.cl
proc future_bahai_new_year_on_or_before(date: int): int =
    ## Return fixed date of Future Bahai New Year on or
    ## before fixed date, date.
    let approx = estimate_prior_solar_longitude(SPRING, sunset_in_haifa(date))
    return next(ifloor(approx) - 1,
                proc(day:int):bool = (solar_longitude(sunset_in_haifa(day)) <=
                             (SPRING + deg(2))))

# see lines 4143-4173 in calendrica-3.0.cl
proc fixed_from_future_bahai(b_date: calBahDate): int =
    ## Return fixed date of Bahai date, b_date.
    let major = bahai_major(b_date)
    let cycle = bahai_cycle(b_date)
    let year  = bahai_year(b_date)
    let month = bahai_month(b_date)
    let day   = bahai_day(b_date)
    let years = (361 * (major - 1)) + (19 * (cycle - 1)) + year
    if (month == 19):
        return (future_bahai_new_year_on_or_before(
            BAHAI_EPOCH +
            ifloor(MEAN_TROPICAL_YEAR.float64 * (years.float64 + 1/2))) -
                20 + day)
    elif (month == AYYAM_I_HA):
        return (future_bahai_new_year_on_or_before(
            BAHAI_EPOCH +
            ifloor(MEAN_TROPICAL_YEAR.float64 * (years.float64 - 1/2))) +
                341 + day)
    else:
        return (future_bahai_new_year_on_or_before(
            BAHAI_EPOCH +
            ifloor(MEAN_TROPICAL_YEAR.float64 * (years.float64 - 1/2))) +
                (19 * (month - 1)) + day - 1)


# see lines 4175-4201 in calendrica-3.0.cl
proc future_bahai_from_fixed*(date: int): calBahDate =
    ## Return Future Bahai date corresponding to fixed date, date.
    let new_year = future_bahai_new_year_on_or_before(date)
    let years    = iround((new_year - BAHAI_EPOCH).float64 / MEAN_TROPICAL_YEAR)
    let major    = 1 + quotient(years, 361)
    let cycle    = 1 + quotient(modulo(years, 361), 19)
    let year     = 1 + modulo(years, 19)
    let days     = date - new_year

    var month: int
    if (date >= fixed_from_future_bahai(bahai_date(major, cycle, year, 19, 1))):
        month = 19
    elif(date >= fixed_from_future_bahai(
        bahai_date(major, cycle, year, AYYAM_I_HA, 1))):
        month = AYYAM_I_HA
    else:
        month = 1 + quotient(days, 19)

    let day  = date + 1 - fixed_from_future_bahai(
        bahai_date(major, cycle, year, month, 1))

    return bahai_date(major, cycle, year, month, day)


# see lines 4203-4213 in calendrica-3.0.cl
proc feast_of_ridvan(g_year: int): int =
    ## Return Fixed date of Feast of Ridvan in Gregorian year year, g_year.
    let years = g_year - gregorian_year_from_fixed(BAHAI_EPOCH)
    let major = 1 + quotient(years, 361)
    let cycle = 1 + quotient(modulo(years, 361), 19)
    let year = 1 + modulo(years, 19)
    return fixed_from_future_bahai(bahai_date(major, cycle, year, 2, 13))


#############################################
## french revolutionary calendar algorithms #
#############################################

# see lines 4218-4220 in calendrica-3.0.cl
proc french_date*(year, month, day: int): calDate =
    ## Return a French Revolutionary date data structure.
    return calDate(year: year, month: month, day: day)

# see lines 4222-4226 in calendrica-3.0.cl
#Fixed date of start of the French Revolutionary calendar.
const FRENCH_EPOCH = fixed_from_gregorian(gregorian_date(1792, SEPTEMBER, 22))

# see lines 4228-4233 in calendrica-3.0.cl
const PARIS = location(angle(48, 50, 11),
                       angle(2, 20, 15),
                       mt(27),
                       days_from_hours(1))

# see lines 4235-4241 in calendrica-3.0.cl
proc midnight_in_paris*(date: int): float64 =
    ## Return Universal Time of true midnight at the end of
    ## fixed date, date.
    # tricky bug: I was using midDAY!!! So French Revolutionary was failing...
    return universal_from_standard(midnight((date + 1).float64, PARIS), PARIS)


# see lines 4243-4252 in calendrica-3.0.cl
proc french_new_year_on_or_before*(date: int): int =
    ## Return fixed date of French Revolutionary New Year on or
    ## before fixed date, date.
    let approx = estimate_prior_solar_longitude(AUTUMN, midnight_in_paris(date))
    return next(ifloor(approx) - 1, 
                proc(day:int):bool = AUTUMN <= solar_longitude(midnight_in_paris(day)))

# see lines 4254-4267 in calendrica-3.0.cl
proc fixed_from_french*(f_date: calDate): int =
    ## Return fixed date of French Revolutionary date, f_date
    let month = standard_month(f_date)
    let day   = standard_day(f_date)
    let year  = standard_year(f_date)
    let new_year = french_new_year_on_or_before(
                      ifloor(FRENCH_EPOCH + 
                            180 + 
                            MEAN_TROPICAL_YEAR * (year - 1).float64))
    return new_year - 1 + 30 * (month - 1) + day

# see lines 4269-4278 in calendrica-3.0.cl
proc french_from_fixed*(date: int): calDate =
    ## Return French Revolutionary date of fixed date, date.
    let new_year = french_new_year_on_or_before(date)
    let year  = iround((new_year - FRENCH_EPOCH).float64 / MEAN_TROPICAL_YEAR) + 1
    let month = quotient(date - new_year, 30) + 1
    let day   = modulo(date - new_year, 30) + 1
    return french_date(year, month, day)

# see lines 4280-4286 in calendrica-3.0.cl
proc is_arithmetic_french_leap_year*(f_year: int): bool =
    ## Return True if year, f_year, is a leap year on the French
    ## Revolutionary calendar.
    return ((modulo(f_year, 4) == 0)                      and 
            (modulo(f_year, 400) notin {100, 200, 300})  and
            (modulo(f_year, 4000) != 0))

# see lines 4288-4302 in calendrica-3.0.cl
proc fixed_from_arithmetic_french*(f_date: calDate): int =
    ## Return fixed date of French Revolutionary date, f_date.
    let month = standard_month(f_date)
    let day   = standard_day(f_date)
    let year  = standard_year(f_date)

    return (FRENCH_EPOCH - 1         +
            365 * (year - 1)         +
            quotient(year - 1, 4)    -
            quotient(year - 1, 100)  +
            quotient(year - 1, 400)  -
            quotient(year - 1, 4000) +
            30 * (month - 1)         +
            day)

# see lines 4304-4325 in calendrica-3.0.cl
proc arithmetic_french_from_fixed*(date: int): calDate =
    ## Return French Revolutionary date [year, month, day] of fixed
    ## date, date.
    let approx = quotient(date - FRENCH_EPOCH + 2, 1460969/4000) + 1
    var year: int
    if date < fixed_from_arithmetic_french(french_date(approx, 1, 1)):
        year = approx - 1
    else:
        year = approx
    let month  = 1 + quotient(date - 
                     fixed_from_arithmetic_french(french_date(year, 1, 1)), 30)
    let day    = date - fixed_from_arithmetic_french(
                           french_date(year, month, 1)) + 1
    return french_date(year, month, day)


################################
## chinese calendar algorithms #
################################

type chinDate = object
    cycle: int
    year: int
    month: int
    leap: bool
    day: int

# see lines 4330-4333 in calendrica-3.0.cl
proc chinese_date*(cycle, year, month: int, leap: bool, day: int): chinDate =
    ## Return a Chinese date data structure.
    return chinDate(cycle: cycle, year: year, month: month, leap: leap, day: day)

# see lines 4335-4337 in calendrica-3.0.cl
proc chinese_cycle*(date: chinDate): int =
    ## Return 'cycle' element of a Chinese date, date.
    return date.cycle

# see lines 4339-4341 in calendrica-3.0.cl
proc chinese_year*(date: chinDate): int =
    ## Return 'year' element of a Chinese date, date.
    return date.year

# see lines 4343-4345 in calendrica-3.0.cl
proc chinese_month*(date: chinDate): int =
    ## Return 'month' element of a Chinese date, date.
    return date.month

# see lines 4347-4349 in calendrica-3.0.cl
proc chinese_leap*(date: chinDate): bool =
    ## Return 'leap' element of a Chinese date, date.
    return date.leap

# see lines 4351-4353 in calendrica-3.0.cl
proc chinese_day(date: chinDate): int =
    ## Return 'day' element of a Chinese date, date.
    return date.day

# see lines 4355-4363 in calendrica-3.0.cl
proc chinese_location*(tee: float64): calLocationData =
    ## Return location of Beijing; time zone varies with time, tee.
    let year = gregorian_year_from_fixed(ifloor(tee))
    if (year < 1929):
        return location(angle(39, 55, 0), angle(116, 25, 0),
                        mt(43.5), days_from_hours(1397/180))
    else:
        return location(angle(39, 55, 0), angle(116, 25, 0),
                        mt(43.5), days_from_hours(8))


# see lines 4365-4377 in calendrica-3.0.cl
proc chinese_solar_longitude_on_or_after*(lam: float64, date: int): float64 =
    ## Return moment (Beijing time) of the first date on or after
    ## fixed date, date, (Beijing time) when the solar longitude
    ## will be 'lam' degrees.
    let tee = solar_longitude_after(lam,
                                    universal_from_standard(date.float64,
                                                            chinese_location(date.float64)))
    return standard_from_universal(tee, chinese_location(tee))

# see lines 4379-4387 in calendrica-3.0.cl
proc current_major_solar_term*(date: int): int = 
    ## Return last Chinese major solar term (zhongqi) before
    ## fixed date, date.
    let s = solar_longitude(universal_from_standard(date.float64,
                                                   chinese_location(date.float64)))
    return amod(2 + quotient(int(s), deg(30)), 12)

proc midnight_in_china*(date: int): float64 {.gcsafe.}

# see lines 4389-4397 in calendrica-3.0.cl
proc major_solar_term_on_or_after*(date: int): float64 =
    ## Return moment (in Beijing) of the first Chinese major
    ## solar term (zhongqi) on or after fixed date, date.  The
    ## major terms begin when the sun's longitude is a
    ## multiple of 30 degrees.
    let sl = solar_longitude(midnight_in_china(date))
    let la = modulo(30 * ceiling(sl / 30), 360)
    return chinese_solar_longitude_on_or_after(la.float64, date)

# see lines 4399-4407 in calendrica-3.0.cl
proc current_minor_solar_term*(date: int): int =
    ## Return last Chinese minor solar term (jieqi) before date, date.
    let s = solar_longitude(universal_from_standard(date.float64,
                                                    chinese_location(date.float64)))
    return amod(3 + quotient(s - deg(15), deg(30)), 12)

# see lines 4409-4422 in calendrica-3.0.cl
proc minor_solar_term_on_or_after*(date: int): float64 =
    ## Return moment (in Beijing) of the first Chinese minor solar
    ## term (jieqi) on or after fixed date, date.  The minor terms
    ## begin when the sun's longitude is an odd multiple of 15 degrees.
    let sl = solar_longitude(midnight_in_china(date))
    let la = modulo(30 * ceiling((sl - deg(15)) / 30) + 15, 360)
    return chinese_solar_longitude_on_or_after(la.float64, date)

# see lines 4424-4433 in calendrica-3.0.cl
proc chinese_new_moon_before*(date: int): int =
    ## Return fixed date (Beijing) of first new moon before fixed date, date.
    let tee = new_moon_before(midnight_in_china(date))
    return ifloor(standard_from_universal(tee, chinese_location(tee)))

# see lines 4435-4444 in calendrica-3.0.cl
proc chinese_new_moon_on_or_after*(date: int): int =
    ## Return fixed date (Beijing) of first new moon on or after
    ## fixed date, date.
    let tee = new_moon_at_or_after(midnight_in_china(date))
    return ifloor(standard_from_universal(tee, chinese_location(tee)))

# see lines 4446-4449 in calendrica-3.0.cl
const CHINESE_EPOCH = fixed_from_gregorian(gregorian_date(-2636, FEBRUARY, 15))

# see lines 4451-4457 in calendrica-3.0.cl
proc is_chinese_no_major_solar_term*(date: int ): bool =
    ## Return True if Chinese lunar month starting on date, date,
    ## has no major solar term.
    return (current_major_solar_term(date) ==
            current_major_solar_term(chinese_new_moon_on_or_after(date + 1)))

# see lines 4459-4463 in calendrica-3.0.cl
proc midnight_in_china*(date: int): float64 =
    ## Return Universal time of (clock) midnight at start of fixed
    ## date, date, in China.
    return universal_from_standard(date.float64, chinese_location(date.float64))

# see lines 4465-4474 in calendrica-3.0.cl
proc chinese_winter_solstice_on_or_before*(date: int): int =
    ## Return fixed date, in the Chinese zone, of winter solstice
    ## on or before fixed date, date.
    let approx = estimate_prior_solar_longitude(WINTER,
                                                midnight_in_china(date + 1))
    return next(ifloor(approx) - 1,
                proc(day:int):bool = WINTER < solar_longitude(
                    midnight_in_china(1 + day)))

# see lines 4476-4500 in calendrica-3.0.cl
proc chinese_new_year_in_sui*(date: int ): int =
    ## Return fixed date of Chinese New Year in sui (period from
    ## solstice to solstice) containing date, date.
    let s1 = chinese_winter_solstice_on_or_before(date)
    let s2 = chinese_winter_solstice_on_or_before(s1 + 370)
    let next_m11 = chinese_new_moon_before(1 + s2)
    let m12 = chinese_new_moon_on_or_after(1 + s1)
    let m13 = chinese_new_moon_on_or_after(1 + m12)
    let leap_year = iround((next_m11 - m12).float64 / MEAN_SYNODIC_MONTH) == 12

    if (leap_year and
        (is_chinese_no_major_solar_term(m12) or is_chinese_no_major_solar_term(m13))):
        return chinese_new_moon_on_or_after(1 + m13)
    else:
        return m13


# see lines 4502-4511 in calendrica-3.0.cl
proc chinese_new_year_on_or_before*(date: int): int =
    ## Return fixed date of Chinese New Year on or before fixed date, date.
    let new_year = chinese_new_year_in_sui(date)
    if (date >= new_year):
        return new_year
    else:
        return chinese_new_year_in_sui(date - 180)

# see lines 4513-4518 in calendrica-3.0.cl
proc chinese_new_year*(g_year: int): int =
    ## Return fixed date of Chinese New Year in Gregorian year, g_year.
    return chinese_new_year_on_or_before(
        fixed_from_gregorian(gregorian_date(g_year, JULY, 1)))


# see lines 4598-4607 in calendrica-3.0.cl
proc is_chinese_prior_leap_month*(m_prime, m: int): bool =
    ## Return True if there is a Chinese leap month on or after lunar
    ## month starting on fixed day, m_prime and at or before
    ## lunar month starting at fixed date, m.
    return ((m >= m_prime) and
            (is_chinese_no_major_solar_term(m) or
             is_chinese_prior_leap_month(m_prime, chinese_new_moon_before(m))))


# see lines 4520-4565 in calendrica-3.0.cl
proc chinese_from_fixed*(date: int): chinDate =
    ## Return Chinese date (cycle year month leap day) of fixed date, date.
    let s1 = chinese_winter_solstice_on_or_before(date)
    let s2 = chinese_winter_solstice_on_or_before(s1 + 370)
    let next_m11 = chinese_new_moon_before(1 + s2)
    let m12 = chinese_new_moon_on_or_after(1 + s1)
    let leap_year = iround((next_m11 - m12).float64 / MEAN_SYNODIC_MONTH) == 12

    let m = chinese_new_moon_before(1 + date)
    let month = amod(iround((m - m12).float64 / MEAN_SYNODIC_MONTH) -
                     (if (leap_year and is_chinese_prior_leap_month(m12, m)): 1 else: 0),
                     12)
    let leap_month = (leap_year and
                      is_chinese_no_major_solar_term(m) and
                      (not is_chinese_prior_leap_month(m12,
                                                    chinese_new_moon_before(m))))
    let elapsed_years = (ifloor(mpf(1.5) -
                               (month / 12) +
                               ((date - CHINESE_EPOCH).float64 / MEAN_TROPICAL_YEAR)))
    let cycle = 1 + quotient(elapsed_years - 1, 60)
    let year = amod(elapsed_years, 60)
    let day = 1 + (date - m)
    return chinese_date(cycle, year, month, leap_month, day)


# see lines 4567-4596 in calendrica-3.0.cl
proc fixed_from_chinese(c_date: chinDate): int =
    ## Return fixed date of Chinese date, c_date.
    let cycle = chinese_cycle(c_date)
    let year  = chinese_year(c_date)
    let month = chinese_month(c_date)
    let leap  = chinese_leap(c_date)
    let day   = chinese_day(c_date)
    let mid_year = ifloor(CHINESE_EPOCH.float64 +
                          ((((cycle - 1) * 60).float64 + (year - 1).float64 + 1/2) *
                           MEAN_TROPICAL_YEAR))
    let new_year = chinese_new_year_on_or_before(mid_year)
    let p = chinese_new_moon_on_or_after(new_year + ((month - 1) * 29))
    let d = chinese_from_fixed(p)
    let prior_new_moon = if month == chinese_month(d) and leap == chinese_leap(d): 
                              0
                          else: 
                              chinese_new_moon_on_or_after(1 + p)
    return prior_new_moon + day - 1



# see lines 4609-4615 in calendrica-3.0.cl
proc chinese_name*(stem, branch: int): (int, int) =
    ## Return BOGUS if stem/branch combination is impossible.
    if modulo(stem, 2) == modulo(branch, 2):
        return (stem, branch)
    else:
        raise newException(ValueError, BOGUS)


# see lines 4617-4619 in calendrica-3.0.cl
proc chinese_stem(name: tuple): int =
    return name[0]


# see lines 4621-4623 in calendrica-3.0.cl
proc chinese_branch(name: tuple): int =
    return name[1]

# see lines 4625-4629 in calendrica-3.0.cl
proc chinese_sexagesimal_name*(n: int): (int, int) =
    ## Return the n_th name of the Chinese sexagesimal cycle.
    return chinese_name(amod(n, 10), amod(n, 12))


# see lines 4631-4644 in calendrica-3.0.cl
proc chinese_name_difference*(c_name1, c_name2: tuple): int =
    ## Return the number of names from Chinese name c_name1 to the
    ## next occurrence of Chinese name c_name2.
    let stem1 = chinese_stem(c_name1)
    let stem2 = chinese_stem(c_name2)
    let branch1 = chinese_branch(c_name1)
    let branch2 = chinese_branch(c_name2)
    let stem_difference   = stem2 - stem1
    let branch_difference = branch2 - branch1
    return 1 + mod(stem_difference - 1 +
                   25 * (branch_difference - stem_difference), 60)


# see lines 4646-4649 in calendrica-3.0.cl
# see lines 214-215 in calendrica-3.0.errata.cl
proc chinese_year_name*(year: int): (int, int) =
    ## Return sexagesimal name for Chinese year, year, of any cycle.
    return chinese_sexagesimal_name(year)


# see lines 4651-4655 in calendrica-3.0.cl
const CHINESE_MONTH_NAME_EPOCH = 57

# see lines 4657-4664 in calendrica-3.0.cl
# see lines 211-212 in calendrica-3.0.errata.cl
proc chinese_month_name*(month, year: int): (int, int) =
    ## Return sexagesimal name for month, month, of Chinese year, year.
    let elapsed_months = (12 * (year - 1)) + (month - 1)
    return chinese_sexagesimal_name(elapsed_months - CHINESE_MONTH_NAME_EPOCH)

# see lines 4666-4669 in calendrica-3.0.cl
const CHINESE_DAY_NAME_EPOCH = rd(45)

# see lines 4671-4675 in calendrica-3.0.cl
# see lines 208-209 in calendrica-3.0.errata.cl
proc chinese_day_name*(date: int): (int, int) =
    ## Return Chinese sexagesimal name for date, date.
    return chinese_sexagesimal_name(date - CHINESE_DAY_NAME_EPOCH)


# see lines 4677-4687 in calendrica-3.0.cl
proc chinese_day_name_on_or_before*(name: tuple, date: int): int =
    ## Return fixed date of latest date on or before fixed date, date, that
    ## has Chinese name, name.
    return (date -
            modulo(date +
                   chinese_name_difference(name,
                               chinese_sexagesimal_name(CHINESE_DAY_NAME_EPOCH)),
                60))


# see lines 4689-4699 in calendrica-3.0.cl
proc dragon_festival*(g_year: int): int =
    ## Return fixed date of the Dragon Festival occurring in Gregorian
    ## year g_year.
    let elapsed_years = 1 + g_year - gregorian_year_from_fixed(CHINESE_EPOCH)
    let cycle = 1 + quotient(elapsed_years - 1, 60)
    let year = amod(elapsed_years, 60)
    return fixed_from_chinese(chinese_date(cycle, year, 5, false, 5))

# see lines 4701-4708 in calendrica-3.0.cl
proc qing_ming*(g_year: int): int = 
    ## Return fixed date of Qingming occurring in Gregorian year, g_year.
    return ifloor(minor_solar_term_on_or_after(
        fixed_from_gregorian(gregorian_date(g_year, MARCH, 30))))


# see lines 4710-4722 in calendrica-3.0.cl
proc chinese_age*(birthdate: chinDate, date: int): int =
    ## Return the age at fixed date, date, given Chinese birthdate, birthdate,
    ## according to the Chinese custom.
    ## Returns BOGUS if date is before birthdate.
    let today = chinese_from_fixed(date)
    if (date >= fixed_from_chinese(birthdate)):
        return (60 * (chinese_cycle(today) - chinese_cycle(birthdate)) +
                (chinese_year(today) -  chinese_year(birthdate)) + 1)
    else:
        raise newException(ValueError, BOGUS)


# see lines 4724-4758 in calendrica-3.0.cl
proc chinese_year_marriage_augury*(cycle, year: int): int =
    ## Return the marriage augury type of Chinese year, year in cycle, cycle.
    ## 0 means lichun does not occur (widow or double-blind years),
    ## 1 means it occurs once at the end (blind),
    ## 2 means it occurs once at the start (bright), and
    ## 3 means it occurs twice (double-bright or double-happiness).
    let new_year = fixed_from_chinese(chinese_date(cycle, year, 1, false, 1))
    let c = if year == 60: cycle + 1 else: cycle
    let y = if year == 60: 1 else: year + 1
    let next_new_year = fixed_from_chinese(chinese_date(c, y, 1, false, 1))
    let first_minor_term = current_minor_solar_term(new_year)
    let next_first_minor_term = current_minor_solar_term(next_new_year)
    if first_minor_term == 1 and next_first_minor_term == 12:
        result = 0
    elif first_minor_term == 1 and next_first_minor_term != 12:
        result = 1
    elif first_minor_term != 1 and next_first_minor_term == 12:
        result = 2
    else:
        result = 3
    return result


# see lines 4760-4769 in calendrica-3.0.cl
proc japanese_location*(tee: float64): calLocationData =
    ## Return the location for Japanese calendar; varies with moment, tee.
    let year = gregorian_year_from_fixed(ifloor(tee))
    if year < 1888:
        # Tokyo (139 deg 46 min east) local time
        result = location(deg(mpf(35.7)), angle(139, 46, 0),
                           mt(24), days_from_hours(9 + 143/450))
    else:
        # Longitude 135 time zone
        result = location(deg(35), deg(135), mt(0), days_from_hours(9))
    return result


# see lines 4771-4795 in calendrica-3.0.cl
proc korean_location*(tee: float64): calLocationData =
    ## Return the location for Korean calendar; varies with moment, tee.
    # Seoul city hall at a varying time zone.
    var z: float64
    if (tee.int < fixed_from_gregorian(gregorian_date(1908, APRIL, 1))):
        #local mean time for longitude 126 deg 58 min
        z = 3809/450
    elif (tee.int < fixed_from_gregorian(gregorian_date(1912, JANUARY, 1))):
        z = 8.5
    elif (tee.int < fixed_from_gregorian(gregorian_date(1954, MARCH, 21))):
        z = 9
    elif (tee.int < fixed_from_gregorian(gregorian_date(1961, AUGUST, 10))):
        z = 8.5
    else:
        z = 9
    return location(angle(37, 34, 0), angle(126, 58, 0),
                    mt(0), days_from_hours(z))


# see lines 4797-4800 in calendrica-3.0.cl
proc korean_year*(cycle, year: int): int =
    ## Return equivalent Korean year to Chinese cycle, cycle, and year, year.
    return (60 * cycle) + year - 364


# see lines 4802-4811 in calendrica-3.0.cl
proc vietnamese_location*(tee: float64): calLocationData =
    ## Return the location for Vietnamese calendar is Hanoi;
    ## varies with moment, tee. Time zone has changed over the years.
    var z: int
    if (tee.int < gregorian_new_year(1968)):
        z = 8
    else:
        z =7
        return location(angle(21, 2, 0), angle(105, 51, 0),
                        mt(12), days_from_hours(z))


######################################
## modern hindu calendars algorithms #
######################################
# see lines 4816-4820 in calendrica-3.0.cl

type hinduLDate = object
    year: int
    month: int
    leap_month: bool
    day: int
    leap_day: bool

proc hindu_lunar_date*(year, month: int, leap_month: bool, day: int, leap_day: bool): hinduLDate =
    # Return a lunar Hindu date data structure.
    return hinduLDate(year: year, month: month, leap_month: leap_month, 
                      day: day, leap_day: leap_day)


# see lines 4822-4824 in calendrica-3.0.cl
proc hindu_lunar_month*(date: hinduLDate): int =
    ## Return 'month' element of a lunar Hindu date, date.
    return date.month


# see lines 4826-4828 in calendrica-3.0.cl
proc hindu_lunar_leap_month*(date: hinduLDate): bool =
    ## Return 'leap_month' element of a lunar Hindu date, date.
    return date.leap_month


# see lines 4830-4832 in calendrica-3.0.cl
proc hindu_lunar_day*(date: hinduLDate): int =
    ## Return 'day' element of a lunar Hindu date, date.
    return date.day


# see lines 4834-4836 in calendrica-3.0.cl
proc hindu_lunar_leap_day*(date: hinduLDate): bool =
    ## Return 'leap_day' element of a lunar Hindu date, date.
    return date.leap_day

# see lines 4838-4840 in calendrica-3.0.cl
proc hindu_lunar_year*(date: hinduLDate): int =
    ## Return 'year' element of a lunar Hindu date, date.
    return date.year

# see lines 4842-4850 in calendrica-3.0.cl
proc hindu_sine_table(entry: int): float64 =
    ## Return the value for entry in the Hindu sine table.
    ## Entry, entry, is an angle given as a multiplier of 225'.
    let exact = 3438 * sin_degrees(entry.float64 * angle(0, 225, 0))
    let error = 0.215 * signum(exact) * signum(abs(exact) - 1716)
    return iround(exact + error) / 3438


# see lines 4852-4861 in calendrica-3.0.cl
proc hindu_sine(theta: float64): float64 =
    ## Return the linear interpolation for angle, theta, in Hindu table.
    let entry    = theta / angle(0, 225, 0)
    let fraction = modulo(entry, 1.0)
    return ((fraction * hindu_sine_table(ceiling(entry))) +
            ((1 - fraction) * hindu_sine_table(ifloor(entry))))


# see lines 4863-4873 in calendrica-3.0.cl
proc hindu_arcsin(amp: float64): float64 =
    ## Return the inverse of Hindu sine function of amp.
    if (amp < 0.0):
        return -hindu_arcsin(-amp)
    else:
        let pos = next(0, proc(k:int):bool = amp <= hindu_sine_table(k))
        let below = hindu_sine_table(pos - 1)
        return (angle(0, 225, 0) *
                (pos.float64 - 1.0 + ((amp - below) / (hindu_sine_table(pos) - below))))


# see lines 4875-4878 in calendrica-3.0.cl
const HINDU_SIDEREAL_YEAR = 365.0 + 279457.0 / 1080000.0

# see lines 4880-4883 in calendrica-3.0.cl
const HINDU_CREATION = HINDU_EPOCH.float64 - 1955880000.0 * HINDU_SIDEREAL_YEAR

# see lines 4885-4889 in calendrica-3.0.cl
proc hindu_mean_position*(tee, period: float64): float64 =
    ## Return the position in degrees at moment, tee, in uniform circular
    ## orbit of period days.
    return deg(360.0) * modulo((tee - HINDU_CREATION) / period, 1.0)

# see lines 4891-4894 in calendrica-3.0.cl
const HINDU_SIDEREAL_MONTH = 27 + mpf(4644439) / mpf(14438334)

# see lines 4896-4899 in calendrica-3.0.cl
const HINDU_SYNODIC_MONTH = 29 + mpf(7087771) / mpf(13358334)

# see lines 4901-4904 in calendrica-3.0.cl
const HINDU_ANOMALISTIC_YEAR = mpf(1577917828000)/(mpf(4320000000) - mpf(387))

# see lines 4906-4909 in calendrica-3.0.cl
const HINDU_ANOMALISTIC_MONTH = mpf(1577917828)/(mpf(57753336) - mpf(488199))

# # see lines 4911-4926 in calendrica-3.0.cl
proc hindu_true_position*(tee, period, size, anomalistic, change: float64): float64 =
    ## Return the longitudinal position at moment, tee.
    ## period is the period of mean motion in days.
    ## size is ratio of radii of epicycle and deferent.
    ## anomalistic is the period of retrograde revolution about epicycle.
    ## change is maximum decrease in epicycle size.
    let lam         = hindu_mean_position(tee, period)
    let offset      = hindu_sine(hindu_mean_position(tee, anomalistic))
    let contraction = abs(offset) * change * size
    let equation    = hindu_arcsin(offset * (size - contraction))
    
    return modulo(lam - equation, 360.0)


# see lines 4928-4932 in calendrica-3.0.cl
proc hindu_solar_longitude*(tee: float64): float64 =
    ## Return the solar longitude at moment, tee.
    return hindu_true_position(tee,
                               HINDU_SIDEREAL_YEAR,
                               14.0 / 360.0,
                               HINDU_ANOMALISTIC_YEAR,
                               1.0 / 42.0)


# see lines 4934-4938 in calendrica-3.0.cl
proc hindu_zodiac*(tee: float64): int =
    ## Return the zodiacal sign of the sun, as integer in range 1..12,
    ## at moment tee.
    return quotient(float64(hindu_solar_longitude(tee)), deg(30)) + 1


# see lines 4940-4944 in calendrica-3.0.cl
proc hindu_lunar_longitude*(tee: float64): float64 =
    ## Return the lunar longitude at moment, tee.
    return hindu_true_position(tee,
                               HINDU_SIDEREAL_MONTH,
                               32/360,
                               HINDU_ANOMALISTIC_MONTH,
                               1/96)


# see lines 4946-4952 in calendrica-3.0.cl
proc hindu_lunar_phase*(tee: float64): float64 =
    ## Return the longitudinal distance between the sun and moon
    ## at moment, tee.
    return modulo(hindu_lunar_longitude(tee) - hindu_solar_longitude(tee), 360.0)


# see lines 4954-4958 in calendrica-3.0.cl
proc hindu_lunar_day_from_moment*(tee: float64): int =
    ## Return the phase of moon (tithi) at moment, tee, as an integer in
    ## the range 1..30.
    return quotient(hindu_lunar_phase(tee), deg(12)) + 1


# see lines 4960-4973 in calendrica-3.0.cl
proc hindu_new_moon_before(tee: float64): float64 =
    ## Return the approximate moment of last new moon preceding moment, tee,
    ## close enough to determine zodiacal sign.
    let varepsilon = pow(2.float64, -1000.float64)
    let tau = tee - ((1/deg(360))   *
                    hindu_lunar_phase(tee) *
                    HINDU_SYNODIC_MONTH)
    return binary_search(tau - 1, min(tee, tau + 1),
                         proc(lo, hi: float64):bool = 
                            ((hindu_zodiac(lo) == hindu_zodiac(hi)) or
                               ((hi - lo) < varepsilon)),
                         proc(x: float64):bool = hindu_lunar_phase(x) < deg(180))


# see lines 4975-4988 in calendrica-3.0.cl
proc hindu_lunar_day_at_or_after*(k, tee: float64): float64 =
    ## Return the time lunar_day (tithi) number, k, begins at or after
    ## moment, tee.  k can be fractional (for karanas).
    let phase = (k - 1) * deg(12)
    let tau   = tee + ((1/deg(360)) *
                       modulo(phase - hindu_lunar_phase(tee), 360.0) *
                       HINDU_SYNODIC_MONTH)
    let a = max(tee, tau - 2)
    let b = tau + 2
    return invert_angular(hindu_lunar_phase, phase, a, b)


# see lines 4990-4996 in calendrica-3.0.cl
proc hindu_calendar_year*(tee: float64): int =
    ## Return the solar year at given moment, tee.
    return iround(((tee - HINDU_EPOCH.float64) / HINDU_SIDEREAL_YEAR) -
                 (hindu_solar_longitude(tee) / deg(360)))


# see lines 4998-5001 in calendrica-3.0.cl
const HINDU_SOLAR_ERA = 3179

proc hindu_sunrise*(date: int): float64 {.gcsafe.}

# see lines 5003-5020 in calendrica-3.0.cl
proc hindu_solar_from_fixed*(date: int): calDate =
    ## Return the Hindu (Orissa) solar date equivalent to fixed date, date.
    let critical = hindu_sunrise(date + 1)
    let month    = hindu_zodiac(critical)
    let year     = hindu_calendar_year(critical) - HINDU_SOLAR_ERA
    let approx   = date - 3 - int(modulo(ifloor(hindu_solar_longitude(critical)), deg(30)))
    let begin    = next(approx,
                        proc(i: int):bool = (hindu_zodiac(hindu_sunrise(i + 1)) ==  month))
    let day      = date - begin + 1
    return hindu_solar_date(year, month, day)


# see lines 5022-5039 in calendrica-3.0.cl
proc fixed_from_hindu_solar*(s_date: calDate): int =
    ## Return the fixed date corresponding to Hindu solar date, s_date,
    ## (Saka era; Orissa rule.)
    let month = standard_month(s_date)
    let day   = standard_day(s_date)
    let year  = standard_year(s_date)
    let begin = ifloor((year.float64 + HINDU_SOLAR_ERA.float64 + ((month - 1)/12)) *
                  HINDU_SIDEREAL_YEAR + HINDU_EPOCH.float64)
    return (day - 1 +
            next(begin - 3,
                 proc(d:int):bool = (hindu_zodiac(hindu_sunrise(d + 1)) == month)))


# see lines 5041-5044 in calendrica-3.0.cl
const HINDU_LUNAR_ERA = 3044

# see lines 5046-5074 in calendrica-3.0.cl
proc hindu_lunar_from_fixed(date: int): hinduLDate =
    ## Return the Hindu lunar date, new_moon scheme, 
    ## equivalent to fixed date, date.
    let critical = hindu_sunrise(date)
    let day      = hindu_lunar_day_from_moment(critical)
    let leap_day = (day == hindu_lunar_day_from_moment(hindu_sunrise(date - 1)))
    let last_new_moon = hindu_new_moon_before(critical)
    let next_new_moon = hindu_new_moon_before((ifloor(last_new_moon) + 35).float64)
    let solar_month   = hindu_zodiac(last_new_moon)
    let leap_month    = (solar_month == hindu_zodiac(next_new_moon))
    let month    = amod(solar_month + 1, 12)
    let year     = (hindu_calendar_year(if month <= 2: date.float64 + 180.0 else: date.float64) -
                    HINDU_LUNAR_ERA)
    return hindu_lunar_date(year, month, leap_month, day, leap_day)


# see lines 5076-5123 in calendrica-3.0.cl
proc fixed_from_hindu_lunar*(l_date: hinduLDate): int =
    ## Return the Fixed date corresponding to Hindu lunar date, l_date.
    let year       = hindu_lunar_year(l_date)
    let month      = hindu_lunar_month(l_date)
    let leap_month = hindu_lunar_leap_month(l_date)
    let day        = hindu_lunar_day(l_date)
    let leap_day   = hindu_lunar_leap_day(l_date)
    let approx = HINDU_EPOCH.float64 + (HINDU_SIDEREAL_YEAR *
                               (year.float64 + HINDU_LUNAR_ERA.float64 + ((month - 1) / 12)))
    let s = ifloor(approx - ((1/deg(360)) *
                             HINDU_SIDEREAL_YEAR.float64 *
                             modulo(hindu_solar_longitude(approx) -
                                    ((month - 1).float64 * deg(30)) +
                                    deg(180), 360.0) -
                             deg(180)))
    let k = hindu_lunar_day_from_moment(s.float64 + days_from_hours(6))
    var temp: int
    if (k > 3 and k < 27):
        temp = k
    else:
        let mid = hindu_lunar_from_fixed(s - 15)
        if ((hindu_lunar_month(mid) != month) or
            (hindu_lunar_leap_month(mid) and not leap_month)):
            temp = modulo(k + 15, 30) - 15
        else:
            temp = modulo(k - 15, 30) + 15
    let est = s + day - temp
    let tau = (est -
               modulo(hindu_lunar_day_from_moment(est.float64 + days_from_hours(6)) - day + 15, 30) +
               15)
    let date = next(tau - 1,
                    proc(d:int):bool = (hindu_lunar_day_from_moment(hindu_sunrise(d)) in
                               [day, amod(day + 1, 30)]))
    return if leap_day: date + 1 else: date

proc hindu_daily_motion*(date: int): float64 {.gcsafe.}

# see lines 5125-5139 in calendrica-3.0.cl
proc hindu_equation_of_time*(date: int): float64 =
    ## Return the time from true to mean midnight of date, date.
    let offset = hindu_sine(hindu_mean_position(date.float64, HINDU_ANOMALISTIC_YEAR))
    let equation_sun = (offset *
                       angle(57, 18, 0) *
                       (14/360 - (abs(offset) / 1080)))
    return ((hindu_daily_motion(date) / deg(360)) *
            (equation_sun / deg(360)) *
            HINDU_SIDEREAL_YEAR)


# see lines 5157-5172 in calendrica-3.0.cl
proc hindu_tropical_longitude*(date: int): float64 =
    ## Return the Hindu tropical longitude on fixed date, date.
    ## Assumes precession with maximum of 27 degrees
    ## and period of 7200 sidereal years (= 1577917828/600 days).
    let days = ifloor(date.float64 - HINDU_EPOCH.float64)
    let precession = (deg(27) -
                     (abs(deg(54) -
                          modulo(deg(27) +
                                 (deg(108) * 600/1577917828 * days.float64),
                                 108.0))))
    return modulo(hindu_solar_longitude(date.float64) - precession, 360.0)


# see lines 5141-5155 in calendrica-3.0.cl
proc hindu_ascensional_difference*(date: int, location: calLocationData): float64 =
    ## Return the difference between right and oblique ascension
    ## of sun on date, date, at loacel, location.
    let sin_delta = (1397/3438) * hindu_sine(hindu_tropical_longitude(date))
    let phi = latitude(location)
    let diurnal_radius = hindu_sine(deg(90) + hindu_arcsin(sin_delta))
    let tan_phi = hindu_sine(phi) / hindu_sine(deg(90) + phi)
    let earth_sine = sin_delta * tan_phi
    return hindu_arcsin(-earth_sine / diurnal_radius)


# see lines 5174-5183 in calendrica-3.0.cl
proc hindu_rising_sign*(date: int): float64 =
    ## Return the tabulated speed of rising of current zodiacal sign on
    ## date, date.
    let i = quotient(float(hindu_tropical_longitude(date)), deg(30))
    return [1670/1800, 1795/1800, 1935/1800, 1935/1800,
            1795/1800, 1670/1800][modulo(i, 6)]


# see lines 5185-5200 in calendrica-3.0.cl
proc hindu_daily_motion*(date: int): float64 =
    ## Return the sidereal daily motion of sun on date, date.
    let mean_motion = deg(360) / HINDU_SIDEREAL_YEAR
    let anomaly     = hindu_mean_position(date.float64, HINDU_ANOMALISTIC_YEAR)
    let epicycle    = 14/360 - abs(hindu_sine(anomaly)) / 1080
    let entry       = quotient(float64(anomaly), angle(0, 225, 0))
    let sine_table_step = hindu_sine_table(entry + 1) - hindu_sine_table(entry)
    let factor = -3438/225 * sine_table_step * epicycle
    return mean_motion * (factor + 1)


# see lines 5202-5205 in calendrica-3.0.cl
proc hindu_solar_sidereal_difference*(date: int): float64 =
    ## Return the difference between solar and sidereal day on date, date.
    return hindu_daily_motion(date) * hindu_rising_sign(date)



# see lines 5218-5228 in calendrica-3.0.cl
proc hindu_sunrise*(date: int): float64 =
    ## Return the sunrise at hindu_location on date, date.
    return (date.float64 + days_from_hours(6) + 
            ((longitude(UJJAIN) - longitude(HINDU_LOCATION)) / deg(360)) -
            hindu_equation_of_time(date) +
            ((1577917828/1582237828 / deg(360)) *
             (hindu_ascensional_difference(date, HINDU_LOCATION) +
              (1/4 * hindu_solar_sidereal_difference(date)))))


# see lines 5230-5244 in calendrica-3.0.cl
proc hindu_fullmoon_from_fixed*(date: int): hinduLDate =
    ## Return the Hindu lunar date, full_moon scheme, 
    ## equivalent to fixed date, date.
    let l_date     = hindu_lunar_from_fixed(date)
    let year       = hindu_lunar_year(l_date)
    let month      = hindu_lunar_month(l_date)
    let leap_month = hindu_lunar_leap_month(l_date)
    let day        = hindu_lunar_day(l_date)
    let leap_day   = hindu_lunar_leap_day(l_date)
    let m = if day >= 16: hindu_lunar_month(hindu_lunar_from_fixed(date + 20))
            else: month
    return hindu_lunar_date(year, m, leap_month, day, leap_day)


# see lines 5246-5255 in calendrica-3.0.cl
proc is_hindu_expunged*(l_month, l_year: int): bool =
    ## Return True if Hindu lunar month l_month in year, l_year
    ## is expunged.
    return (l_month !=
            hindu_lunar_month(
                hindu_lunar_from_fixed(
                    fixed_from_hindu_lunar(
                        hindu_lunar_date(l_year, l_month, false, 15, false)))))


# see lines 5257-5272 in calendrica-3.0.cl
proc fixed_from_hindu_fullmoon*(l_date: hinduLDate): int =
    ## Return the fixed date equivalent to Hindu lunar date, l_date,
    ## in full_moon scheme.
    let year       = hindu_lunar_year(l_date)
    let month      = hindu_lunar_month(l_date)
    let leap_month = hindu_lunar_leap_month(l_date)
    let day        = hindu_lunar_day(l_date)
    let leap_day   = hindu_lunar_leap_day(l_date)

    var m: int
    if leap_month or day <= 15:
        m = month
    elif is_hindu_expunged(amod(month - 1, 12), year):
        m = amod(month - 2, 12)
    else:
        m = amod(month - 1, 12)
    return fixed_from_hindu_lunar(
        hindu_lunar_date(year, m, leap_month, day, leap_day))


# see lines 5274-5280 in calendrica-3.0.cl
proc alt_hindu_sunrise*(date: int): float64 =
    ## Return the astronomical sunrise at Hindu location on date, date,
    ## per Lahiri, rounded to nearest minute, as a rational number.
    let rise = dawn(date.float64, HINDU_LOCATION, angle(0, 47, 0))
    return 1/24 * 1/60 * iround(rise * 24 * 60).float64


# see lines 5282-5292 in calendrica-3.0.cl
proc hindu_sunset*(date: int): float64 =
    ## Return sunset at HINDU_LOCATION on date, date.
    return (date.float64 + days_from_hours(18) + 
            ((longitude(UJJAIN) - longitude(HINDU_LOCATION)) / deg(360)) -
            hindu_equation_of_time(date) +
            (((1577917828/1582237828) / deg(360)) *
             (- hindu_ascensional_difference(date, HINDU_LOCATION) +
              (3/4 * hindu_solar_sidereal_difference(date)))))


# see lines 5294-5313 in calendrica-3.0.cl
proc hindu_sundial_time*(tee: float64): float64 =
    ## Return Hindu local time of temporal moment, tee.
    let date = fixed_from_moment(tee)
    let time = modulo(tee, 1.0)
    let q    = ifloor(4 * time)
    var a, b, t: float64
    if q == 0:
        a = hindu_sunset(date - 1)
        b = hindu_sunrise(date)
        t = days_from_hours(-6)
    elif q == 3:
        a = hindu_sunset(date)
        b = hindu_sunrise(date + 1)
        t = days_from_hours(18)
    else:
        a = hindu_sunrise(date)
        b = hindu_sunset(date)
        t = days_from_hours(6)
    return a + (2 * (b - a) * (time - t))


# see lines 5315-5318 in calendrica-3.0.cl
proc ayanamsha*(tee: float64): float64 =
    ## Return the difference between tropical and sidereal solar longitude.
    return solar_longitude(tee) - sidereal_solar_longitude(tee)


# see lines 5320-5323 in calendrica-3.0.cl
proc astro_hindu_sunset*(date: int): float64 =
    ## Return the geometrical sunset at Hindu location on date, date.
    return dusk(date.float64, HINDU_LOCATION, deg(0))


# see lines 5325-5329 in calendrica-3.0.cl
proc sidereal_zodiac*(tee: float64): int =
    ## Return the sidereal zodiacal sign of the sun, as integer in range
    ## 1..12, at moment, tee.
    return quotient(int(sidereal_solar_longitude(tee)), deg(30)) + 1


# see lines 5331-5337 in calendrica-3.0.cl
proc astro_hindu_calendar_year*(tee: float64): int =
    ## Return the astronomical Hindu solar year KY at given moment, tee.
    return iround(((tee - HINDU_EPOCH.float64) / MEAN_SIDEREAL_YEAR) -
                 (sidereal_solar_longitude(tee) / deg(360)))


# see lines 5339-5357 in calendrica-3.0.cl
proc astro_hindu_solar_from_fixed*(date: int): calDate =
    ## Return the Astronomical Hindu (Tamil) solar date equivalent to
    ## fixed date, date.
    let critical = astro_hindu_sunset(date)
    let month    = sidereal_zodiac(critical)
    let year     = astro_hindu_calendar_year(critical) - HINDU_SOLAR_ERA
    let approx   = (date - 3 -
                    modulo(ifloor(sidereal_solar_longitude( critical)), 30))
    let begin    = next(approx,
                        proc(i:int):bool = sidereal_zodiac(astro_hindu_sunset(i)) == month)
    let day      = date - begin + 1
    return hindu_solar_date(year, month, day)


# see lines 5359-5375 in calendrica-3.0.cl
proc fixed_from_astro_hindu_solar*(s_date: calDate): int =
    ## Return the fixed date corresponding to Astronomical 
    ## Hindu solar date (Tamil rule; Saka era).
    let month = standard_month(s_date)
    let day   = standard_day(s_date)
    let year  = standard_year(s_date)
    let approx = (HINDU_EPOCH - 3 +
                  ifloor(((year + HINDU_SOLAR_ERA).float64 + ((month - 1) / 12)) *
                        MEAN_SIDEREAL_YEAR))
    let begin = next(approx,
                     proc(i:int):bool = sidereal_zodiac(astro_hindu_sunset(i)) == month)
    return begin + day - 1


# see lines 5377-5381 in calendrica-3.0.cl
proc astro_lunar_day_from_moment*(tee: float64): int =
    ## Return the phase of moon (tithi) at moment, tee, as an integer in
    ## the range 1..30.
    return quotient(lunar_phase(tee), deg(12)) + 1


# see lines 5383-5410 in calendrica-3.0.cl
proc astro_hindu_lunar_from_fixed*(date: int): hinduLDate =
    ## Return the astronomical Hindu lunar date equivalent to
    ## fixed date, date.
    let critical = alt_hindu_sunrise(date)
    let day      = astro_lunar_day_from_moment(critical)
    let leap_day = (day == astro_lunar_day_from_moment(
                              alt_hindu_sunrise(date - 1)))
    let last_new_moon = new_moon_before(critical)
    let next_new_moon = new_moon_at_or_after(critical)
    let solar_month   = sidereal_zodiac(last_new_moon)
    let leap_month    = solar_month == sidereal_zodiac(next_new_moon)
    let month    = amod(solar_month + 1, 12)
    let year     = astro_hindu_calendar_year(if month <= 2: date.float64 + 180
                                             else: date.float64 - HINDU_LUNAR_ERA)
    return hindu_lunar_date(year, month, leap_month, day, leap_day)


# see lines 5412-5460 in calendrica-3.0.cl
proc fixed_from_astro_hindu_lunar*(l_date: hinduLDate): int =
    ## Return the fixed date corresponding to Hindu lunar date, l_date.
    let year  = hindu_lunar_year(l_date)
    let month = hindu_lunar_month(l_date)
    let leap_month = hindu_lunar_leap_month(l_date)
    let day   = hindu_lunar_day(l_date)
    let leap_day = hindu_lunar_leap_day(l_date)
    let approx = (HINDU_EPOCH.float64 +
                  MEAN_SIDEREAL_YEAR *
                  (year.float64 + HINDU_LUNAR_ERA + ((month - 1) / 12)))
    let s = ifloor(approx -
                  1/deg(360) * MEAN_SIDEREAL_YEAR *
                  (modulo(sidereal_solar_longitude(approx) -
                         (month.float64 - 1) * deg(30) + deg(180), deg(360)) - deg(180)))
    let k = astro_lunar_day_from_moment(s.float64 + days_from_hours(6))
    var temp: int
    if k > 3 and k < 27:    
        temp = k
    else:
        let mid = astro_hindu_lunar_from_fixed(s - 15)
        if ((hindu_lunar_month(mid) != month) or
            (hindu_lunar_leap_month(mid) and not leap_month)):
            temp = modulo(k + 15, 30) - 15
        else:
            temp = modulo(k - 15, 30) + 15
    let est = s + day - temp
    let tau = (est -
               modulo(astro_lunar_day_from_moment(est.float64 + days_from_hours(6)) - day + 15, 30) +
               15)
    let date = next(tau - 1,
                    proc(d:int):bool = (astro_lunar_day_from_moment(alt_hindu_sunrise(d)) in
                                       [day, amod(day + 1, 30)]))
    return if leap_day: date + 1 else: date


# see lines 5462-5467 in calendrica-3.0.cl
proc hindu_lunar_station*(date: int): int =
    ## Return the Hindu lunar station (nakshatra) at sunrise on date, date.
    let critical = hindu_sunrise(date)
    return quotient(hindu_lunar_longitude(critical), angle(0, 800, 0)) + 1


# see lines 5469-5480 in calendrica-3.0.cl
proc hindu_solar_longitude_at_or_after*(lam, tee: float64): float64 =
    ## Return the moment of the first time at or after moment, tee
    ## when Hindu solar longitude will be lam degrees.
    let tau = tee + (HINDU_SIDEREAL_YEAR *
                     (1 / deg(360)) *
                     modulo(lam - hindu_solar_longitude(tee), 360.0))
    let a = max(tee, tau - 5)
    let b = tau + 5
    return invert_angular(hindu_solar_longitude, lam, a, b)


# see lines 5482-5487 in calendrica-3.0.cl
proc mesha_samkranti*(g_year: int): float64 =
    ## Return the fixed moment of Mesha samkranti (Vernal equinox)
    ## in Gregorian year, g_year.
    let jan1 = gregorian_new_year(g_year)
    return hindu_solar_longitude_at_or_after(deg(0), jan1.float64)



# see lines 5495-5513 in calendrica-3.0.cl
proc hindu_lunar_new_year*(g_year:int): int =
    ## Return the fixed date of Hindu lunisolar new year in
    ## Gregorian year, g_year.
    let jan1     = gregorian_new_year(g_year)
    let mina     = hindu_solar_longitude_at_or_after(deg(330), jan1.float64)
    let new_moon = hindu_lunar_day_at_or_after(1, mina)
    var h_day    = ifloor(new_moon)
    let critical = hindu_sunrise(h_day)

    if new_moon < critical or
       hindu_lunar_day_from_moment(hindu_sunrise(h_day + 1)) == 2:
        h_day += 0
    else: 
        h_day += 1
    return h_day 


# see lines 5515-5539 in calendrica-3.0.cl
proc is_hindu_lunar_on_or_before*(l_date1, l_date2: hinduLDate): bool =
    ## Return True if Hindu lunar date, l_date1 is on or before
    ## Hindu lunar date, l_date2.
    let month1 = hindu_lunar_month(l_date1)
    let month2 = hindu_lunar_month(l_date2)
    let leap1  = hindu_lunar_leap_month(l_date1)
    let leap2  = hindu_lunar_leap_month(l_date2)
    let day1   = hindu_lunar_day(l_date1)
    let day2   = hindu_lunar_day(l_date2)
    let leap_day1 = hindu_lunar_leap_day(l_date1)
    let leap_day2 = hindu_lunar_leap_day(l_date2)
    let year1  = hindu_lunar_year(l_date1)
    let year2  = hindu_lunar_year(l_date2)
    return ((year1 < year2) or
            ((year1 == year2) and
             ((month1 < month2) or
              ((month1 == month2) and
               ((leap1 and not leap2) or
                ((leap1 == leap2) and
                 ((day1 < day2) or
                  ((day1 == day2) and
                   ((not leap_day1) or
                    leap_day2)))))))))


# see lines 5941-5967 in calendrica-3.0.cl
proc hindu_date_occur*(l_month, l_day, l_year: int): int =
    ## Return the fixed date of occurrence of Hindu lunar month, l_month,
    ## day, l_day, in Hindu lunar year, l_year, taking leap and
    ## expunged days into account.  When the month is
    ## expunged, then the following month is used.
    let lunar = hindu_lunar_date(l_year, l_month, false, l_day, false)
    let ttry   = fixed_from_hindu_lunar(lunar)
    let mid   = hindu_lunar_from_fixed(if l_day > 15: ttry - 5 else: ttry)
    let expunged = l_month != hindu_lunar_month(mid)
    let l_date = hindu_lunar_date(hindu_lunar_year(mid),
                                  hindu_lunar_month(mid),
                                  hindu_lunar_leap_month(mid),
                                  l_day,
                                  false)
    if expunged:
        return next(ttry,
                    proc(d:int):bool = (not is_hindu_lunar_on_or_before(
                                                hindu_lunar_from_fixed(d),
                                                l_date))) - 1
    elif l_day != hindu_lunar_day(hindu_lunar_from_fixed(ttry)):
        return ttry - 1
    else:
        return ttry


# see lines 5969-5980 in calendrica-3.0.cl
proc hindu_lunar_holiday*(l_month, l_day, g_year: int): seq[int] =
    ## Return the list of fixed dates of occurrences of Hindu lunar
    ## month, month, day, day, in Gregorian year, g_year.
    let l_year = hindu_lunar_year(
        hindu_lunar_from_fixed(gregorian_new_year(g_year)))
    let date1  = hindu_date_occur(l_month, l_day, l_year)
    let date2  = hindu_date_occur(l_month, l_day, l_year + 1)
    return list_range([date1, date2], gregorian_year_range(g_year))


# see lines 5582-5586 in calendrica-3.0.cl
proc diwali*(g_year: int): seq[int] =
    ## Return the list of fixed date(s) of Diwali in Gregorian year, g_year.
    return hindu_lunar_holiday(8, 1, g_year)


# see lines 5588-5605 in calendrica-3.0.cl
proc hindu_tithi_occur*(l_month: int, tithi, tee: float, l_year: int): int =
    ## Return the fixed date of occurrence of Hindu lunar tithi prior
    ## to sundial time, tee, in Hindu lunar month, l_month, and
    ## year, l_year.
    let approx = hindu_date_occur(l_month, ifloor(tithi), l_year)
    let lunar  = hindu_lunar_day_at_or_after(tithi.float64, approx.float64 - 2)
    let ttry   = fixed_from_moment(lunar)
    let tee_h  = standard_from_sundial((ttry.float64 + tee), UJJAIN)
    if ((lunar <= tee_h) or
        (hindu_lunar_phase(standard_from_sundial((ttry.float64 + 1 + tee).float64, UJJAIN)) >
         (12 * tithi.float64))):
        return ttry
    else:
        return ttry + 1


# see lines 5607-5620 in calendrica-3.0.cl
proc hindu_lunar_event*(l_month: int, tithi, tee: float64, g_year: int): seq[int] =
    ## Return the list of fixed dates of occurrences of Hindu lunar tithi
    ## prior to sundial time, tee, in Hindu lunar month, l_month,
    ## in Gregorian year, g_year.
    let l_year = hindu_lunar_year(
        hindu_lunar_from_fixed(gregorian_new_year(g_year)))
    let date1  = hindu_tithi_occur(l_month, tithi, tee, l_year)
    let date2  = hindu_tithi_occur(l_month, tithi, tee, l_year + 1)
    return list_range([date1, date2],
                      gregorian_year_range(g_year))


# see lines 5622-5626 in calendrica-3.0.cl
proc shiva*(g_year: int): seq[int] =
    ## Return the list of fixed date(s) of Night of Shiva in Gregorian
    ## year, g_year.
    return hindu_lunar_event(11, 29, days_from_hours(24), g_year)


# see lines 5628-5632 in calendrica-3.0.cl
proc rama(g_year: int): seq[int] =
    ## Return the list of fixed date(s) of Rama's Birthday in Gregorian
    ## year, g_year.
    return hindu_lunar_event(1, 9, days_from_hours(12), g_year)


# see lines 5634-5640 in calendrica-3.0.cl
proc karana*(n: int): int =
    ## Return the number (0-10) of the name of the n-th (1-60) Hindu
    ## karana.
    if (n == 1):
        return 0
    elif (n > 57):
        return n - 50
    else:
        return amod(n - 1, 7)


# see lines 5642-5648 in calendrica-3.0.cl
proc yoga*(date: int): int =
    ## Return the Hindu yoga on date, date.
    return ifloor(modulo((hindu_solar_longitude(date.float64) +
                 hindu_lunar_longitude(date.float64)) / angle(0, 800, 0), 27)) + 1


# see lines 5657-5672 in calendrica-3.0.cl
proc sacred_wednesdays_in_range*(range: tuple): seq[int] = 
    ## Return the list of Wednesdays within range of dates
    ## that are day 8 of Hindu lunar months.
    let a      = start(range)
    let b      = endr(range)
    let wed    = kday_on_or_after(WEDNESDAY, a)
    let h_date = hindu_lunar_from_fixed(wed)

    if (hindu_lunar_day(h_date) == 8):
        result = @[wed]
    else:
        result = @[]

    if is_in_range(wed, range):
        result.add(sacred_wednesdays_in_range(interval(wed + 1, b)))


# see lines 5650-5655 in calendrica-3.0.cl
proc sacred_wednesdays*(g_year: int): seq[int] = 
    ## Return the list of Wednesdays in Gregorian year, g_year,
    ## that are day 8 of Hindu lunar months.
    return sacred_wednesdays_in_range(gregorian_year_range(g_year))


################################
## tibetan calendar algorithms #
################################

# see lines 5677-5681 in calendrica-3.0.cl
proc tibetan_date*(year, month: int, leap_month: bool, day: int, leap_day: bool): hinduLDate =
    ## Return a Tibetan date data structure.
    return hinduLDate(year: year, month: month, leap_month: leap_month, day: day, leap_day: leap_day)


# see lines 5683-5685 in calendrica-3.0.cl
proc tibetan_month*(date: hinduLDate): int =
    ## Return 'month' element of a Tibetan date, date.
    return date.month


# see lines 5687-5689 in calendrica-3.0.cl
proc tibetan_leap_month*(date: hinduLDate): bool =
    ## Return 'leap month' element of a Tibetan date, date.
    return date.leap_month

# see lines 5691-5693 in calendrica-3.0.cl
proc tibetan_day*(date: hinduLDate): int =
    ## Return 'day' element of a Tibetan date, date.
    return date.day

# see lines 5695-5697 in calendrica-3.0.cl
proc tibetan_leap_day*(date: hinduLDate): bool =
    ## Return 'leap day' element of a Tibetan date, date.
    return date.leap_day

# see lines 5699-5701 in calendrica-3.0.cl
proc tibetan_year*(date: hinduLDate): int =
    ## Return 'year' element of a Tibetan date, date.
    return date.year

# see lines 5703-5705 in calendrica-3.0.cl
const TIBETAN_EPOCH = fixed_from_gregorian(gregorian_date(-127, DECEMBER, 7))

# see lines 5707-5717 in calendrica-3.0.cl
proc tibetan_sun_equation*[T](alpha: T): float64 =
    ## Return the interpolated tabular sine of solar anomaly, alpha.
    if (alpha > 6):
        return -tibetan_sun_equation(alpha - 6)
    elif (alpha > 3):
        return tibetan_sun_equation(6 - alpha)
    elif alpha is int:
        return [0.0, 6/60, 10/60, 11/60][alpha]
    else:
        return ((modulo(alpha, 1.0) * tibetan_sun_equation(ceiling(alpha.float64))) +
                (modulo(-alpha, 1.0) * tibetan_sun_equation(ifloor(alpha.float64))))


# see lines 5719-5731 in calendrica-3.0.cl
proc tibetan_moon_equation*[T](alpha: T): float64 =
    ## Return the interpolated tabular sine of lunar anomaly, alpha.
    if (alpha > 14):
        return -tibetan_moon_equation(alpha - 14)
    elif (alpha > 7):
        return tibetan_moon_equation(14 - alpha)
    elif alpha is int:
        return [0.0, 5/60, 10/60, 15/60,
                19/60, 22/60, 24/60, 25/60][alpha]
    else:
        return ((modulo(alpha, 1.0) * tibetan_moon_equation(ceiling(alpha.float64))) +
                (modulo(-alpha, 1.0) * tibetan_moon_equation(ifloor(alpha.float64))))
    

# see lines 5733-5755 in calendrica-3.0.cl
proc fixed_from_tibetan*(t_date: hinduLDate): int =
    ## Return the fixed date corresponding to Tibetan lunar date, t_date.
    let year       = tibetan_year(t_date)
    let month      = tibetan_month(t_date)
    let leap_month = tibetan_leap_month(t_date)
    let day        = tibetan_day(t_date)
    let leap_day   = tibetan_leap_day(t_date)
    let months = ifloor((804/65 * (year - 1).float64) +
                       (67/65 * month.float64) +
                       (if leap_month: -1 else: 0) +
                       64/65)
    let days = (30 * months) + day
    let mean = ((days * 11135/11312) - 30 +
                (if leap_day: 0 else: -1) +
                1071/1616)
    let solar_anomaly = modulo((days * 13/4824) + 2117/4824, 1)
    let lunar_anomaly = modulo((days * 3781/105840) +
                            2837/15120, 1)
    let sun  = -tibetan_sun_equation(12 * solar_anomaly)
    let moon = tibetan_moon_equation(28 * lunar_anomaly)
    return ifloor(TIBETAN_EPOCH.float64 + mean + sun + moon)


# see lines 5757-5796 in calendrica-3.0.cl
proc tibetan_from_fixed*(date: int): hinduLDate =
    ## Return the Tibetan lunar date corresponding to fixed date, date.
    let cap_Y = 365 + 4975/18382
    let years = ceiling((date - TIBETAN_EPOCH).float64 / cap_Y)
    let year0 = final(years,
                     proc(y:int):bool =(date >=
                               fixed_from_tibetan(
                                   tibetan_date(y, 1, false, 1, false))))
    let month0 = final(1,
                      proc(m:int):bool = (date >=
                                 fixed_from_tibetan(
                                     tibetan_date(year0, m, false, 1, false))))
    let est = date - fixed_from_tibetan(
           tibetan_date(year0, month0, false, 1, false))
    let day0 = final(est - 2,
                    proc(d:int):bool = (date >=
                               fixed_from_tibetan(
                                   tibetan_date(year0, month0, false, d, false))))
    let leap_month = (day0 > 30)
    let day = amod(day0, 30)

    var temp: int
    if (day > day0):
        temp = month0 - 1
    elif leap_month:
        temp = month0 + 1
    else:
        temp = month0
    let month = amod(temp, 12)
    
    var year: int
    if ((day > day0) and (month0 == 1)):
        year = year0 - 1
    elif (leap_month and (month0 == 12)):
        year = year0 + 1
    else:
        year = year0
    let leap_day = date == fixed_from_tibetan(
           tibetan_date(year, month, leap_month, day, true))
    return tibetan_date(year, month, leap_month, day, leap_day)


# see lines 5798-5805 in calendrica-3.0.cl
proc is_tibetan_leap_month*(t_month, t_year: int): bool =
    ## Return True if t_month is leap in Tibetan year, t_year.
    return (t_month ==
            tibetan_month(tibetan_from_fixed(
                fixed_from_tibetan(
                    tibetan_date(t_year, t_month, true, 2, false)))))


# see lines 5807-5813 in calendrica-3.0.cl
proc losar*(t_year: int): int =
    ## Return the  fixed date of Tibetan New Year (Losar)
    ## in Tibetan year, t_year.
    let t_leap = is_tibetan_leap_month(1, t_year)
    return fixed_from_tibetan(tibetan_date(t_year, 1, t_leap, 1, false))

# see lines 5815-5824 in calendrica-3.0.cl
proc tibetan_new_year(g_year: int): seq[int] =
    ## Return the list of fixed dates of Tibetan New Year in
    ## Gregorian year, g_year.
    let dec31  = gregorian_year_end(g_year)
    let t_year = tibetan_year(tibetan_from_fixed(dec31))
    return list_range([losar(t_year - 1), losar(t_year)],
                      gregorian_year_range(g_year))


proc timeinfo_from_moment*(moment: float64): TimeInfo =
    let date = gregorian_from_fixed(fixed_from_moment(moment))
    let time = clock_from_moment(moment)
    result = TimeInfo(year: date.year, 
                      month: Month(date.month - 1), 
                      monthday: date.day,
                      hour: time.hour,
                      minute: time.minute,
                      second: iround(time.second))
    return result

proc full_moons_in_year(year: int): seq[TimeInfo] =
    result = @[]
    let start = fixed_from_gregorian(gregorian_date(year, 1, 1))
    let endpoint = fixed_from_gregorian(gregorian_date(year+1, 1, 1)).float64
    var moment = start.float64
    while true:
        moment = lunar_phase_at_or_after(FULL, moment)
        if moment >= endpoint:
            break
        result.add(timeinfo_from_moment(moment))
        moment += 1.0
    return result

proc ramadan_in_year(year: int): (calDate, calDate) =
    let islamic_year = islamic_from_fixed(fixed_from_gregorian(gregorian_date(year, 1, 1))).year
    let start = gregorian_from_fixed(fixed_from_islamic(islamic_date(islamic_year, 9, 1)))
    let endd = gregorian_from_fixed(fixed_from_islamic(islamic_date(islamic_year, 10, 1))-1)
    return (start, endd)


# # That's all folks!
when isMainModule:
    import strutils
    # var dates = @[710347, fixed_from_now(), easter(2017), 
    #               orthodox_easter(2017), easter(2018),
    #               orthodox_easter(2018), independence_day(2017),
    #               independence_day(2018),
    #               fixed_from_gregorian(gregorian_date(2017, 12, 31))]
    # for x in dates:
    #     echo "gregorian: ", gregorian_from_fixed(x), ", ", fixed_from_gregorian(gregorian_from_fixed(x))
    #     echo "julian:    ", julian_from_fixed(x), ", ", fixed_from_julian(julian_from_fixed(x))
    #     echo "ISO:       ", iso_from_fixed(x), ", ", fixed_from_iso(iso_from_fixed(x))
    #     echo "islamic:   ", islamic_from_fixed(x), ", ", fixed_from_islamic(islamic_from_fixed(x))
    #     echo "hebrew     ", hebrew_from_fixed(x), ", ", fixed_from_hebrew(hebrew_from_fixed(x)) 
    #     echo gregorian_year_from_fixed(x)

    # echo "-".repeat(80)
    # echo "yom_kippur(2017): ", yom_kippur(2017), ", ", gregorian_from_fixed(yom_kippur(2017))
    # echo "sunset:    ", sunset((yom_kippur(2017)-1).float64, JERUSALEM)
    # echo "nightfall: ", sunset(yom_kippur(2017).float64, JERUSALEM)
    # echo "yom_kippur(2016): ", yom_kippur(2016), ", ", gregorian_from_fixed(yom_kippur(2016))
    # echo "sunset:    ", $timeInfoFromMoment(sunset((yom_kippur(2016)-1).float64, JERUSALEM))
    # echo "nightfall: ", $timeInfoFromMoment(sunset((yom_kippur(2016)).float64, JERUSALEM))

    let curr_year = getLocalTime(getTime()).year
    let now = fixed_from_now()
    echo "now: ", gregorian_from_fixed(now)
    let hebrew_current = hebrew_from_fixed(now)
    echo "hebrew now: ", hebrew_current

    echo "-".repeat(80)
    echo "next 20 Hebrew New Years"
    var hyr = hebrew_current.year
    for yr in hyr+1..hyr+21:
      let new_yr = hebrew_new_year(yr)
      echo gregorian_from_fixed(new_yr), " ", hebrew_from_fixed(new_yr)

    echo "-".repeat(80) 
    echo "Full Moons:"


    for fullmoon in full_moons_in_year(curr_year):
        echo $getLocalTime(fullmoon.toTime())

    echo "-".repeat(80)
    echo "Ramadan in the next 10 years:"
    for yr in curr_year..curr_year+10:
        let (x, y) = ramadan_in_year(yr)
        echo $x, " - ", $y

    echo "-".repeat(80)
    echo "Easter and orthodox Easter in the next 10 years:"
    for yr in curr_year..curr_year+10:
        let e = easter(yr)
        let oe = orthodox_easter(yr)
        echo gregorian_from_fixed(e), " ", gregorian_from_fixed(oe) 

    echo "-".repeat(80)
    echo "Hindu Tithis until end of Year:"
    let year_end = gregorian_year_end(curr_year)
    var current: int = now + 1
    for i in 1..year_end-now:
        echo gregorian_from_fixed(current), ": ", astro_lunar_day_from_moment(current.float64)
        inc(current)

    echo "-".repeat(80)
    echo "next full moon:"
    echo gregorian_from_fixed(lunar_phase_at_or_after(FULL, float(now)).int)
    echo "next new moon:"
    echo gregorian_from_fixed(lunar_phase_at_or_after(NEW, float(now)).int)


    echo "-".repeat(80)
    echo "MESZ start and end in the next 10 Years"
    for yr in curr_year..curr_year + 11:
      let start = last_kday(SUNDAY, gregorian_date(yr, 3, 31))
      let stop = last_kday(SUNDAY, gregorian_date(yr, 10, 31))
      echo gregorian_from_fixed(start), " - ", gregorian_from_fixed(stop)

    echo "-".repeat(80)
    echo "Sundays in Advent in the next 10 Years"
    for yr in curr_year..curr_year+11:
      let frst = nth_kday(-4, SUNDAY, gregorian_date(yr, 12, 24))
      echo gregorian_from_fixed(frst), " ", gregorian_from_fixed(frst+7), " ",
           gregorian_from_fixed(frst + 7 * 2), " ", gregorian_from_fixed(frst + 7 * 3)
    
    echo "-".repeat(80)
    echo "ISO Week until end of next Year"
    current = now
    var current_iso = iso_from_fixed(current)
    var idx = fixed_from_iso(iso_date(current_iso.year, current_iso.week, 1))
    let stop = gregorian_year_end(current_iso.year + 1)
    while true:
      if idx >= stop:
        break
      let curr_iso = iso_from_fixed(idx)
      var week_nr = ""
      if curr_iso.week < 10:
        week_nr.add(" ")
      week_nr.add($curr_iso.week)

      echo week_nr, ": ", gregorian_from_fixed(idx), " - ", gregorian_from_fixed(idx + 7)
      idx += 8

