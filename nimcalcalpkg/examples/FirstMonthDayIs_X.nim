import os
import strutils
import times
import nimcalcal

iterator find_matching_dates(start, stop, wd: int): int =
  var a = start
  var d: calDate
  a = kday_on_or_after(wd, a)
  while a <= stop:
    d = gregorian_from_fixed(a)
    if standard_day(d) == 1:
      yield a
    a = kday_on_or_after(wd, a + 1)

when isMainModule:
  let start_year = parseInt(paramStr(1))
  let stop_year = parseInt(paramStr(2))
  let weekday = parseInt(paramStr(3))
  let start = fixed_from_gregorian(gregorian_date(start_year, 1, 1))
  let stop = fixed_from_gregorian(gregorian_date(stop_year, 1, 1))
  for d in find_matching_dates(start, stop, weekday):
    #let nd = timeinfo_from_moment(d.float64)
    echo gregorian_from_fixed(d), " ", day_of_week_from_fixed(d)

