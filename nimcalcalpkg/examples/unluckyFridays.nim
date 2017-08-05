import os
import strutils
import times
import nimcalcal

iterator get_unlucky_fridays(start, stop: int): int =
  var a = start
  var d: calDate
  a = kday_on_or_after(FRIDAY, a+1)
  while a <= stop:
    d = gregorian_from_fixed(a)
    if standard_day(d) == 13:
      yield a
    a = kday_on_or_after(FRIDAY, a + 1)

iterator get_lucky_sundays(start, stop: int): int =
  var a = start
  var d: calDate
  a = kday_on_or_after(SUNDAY, a+1)
  while a <= stop:
    d = gregorian_from_fixed(a)
    if standard_day(d) == 1:
      yield a
    a = kday_on_or_after(SUNDAY, a + 1)

when isMainModule:
  let start_year = parseInt(paramStr(1))
  let stop_year = parseInt(paramStr(2))
  let start = fixed_from_gregorian(gregorian_date(start_year, 1, 1))
  let stop = fixed_from_gregorian(gregorian_date(stop_year, 1, 1))
  for d in get_unlucky_fridays(start, stop):
    let nd = timeinfo_from_moment(d.float64)
    echo gregorian_from_fixed(d), " ", format(nd, "dddd dd'.' MMMM yyyyy"), " ", $nd.year, " ", $nd

  var dstr = "1970-11-16"
  var dt = parse(dstr, "yyyy-MM-dd")
  echo $dt
  dt = dt + 480.years
  echo $dt
  echo getDayofWeek(16, 11, 4713)
  echo day_of_week_from_fixed(fixed_from_gregorian(gregorian_date(4713, 11, 16)))
  echo getDayofWeekJulian(16, 11, 4713)

