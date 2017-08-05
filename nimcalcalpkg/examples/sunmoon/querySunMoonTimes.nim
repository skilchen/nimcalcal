import times
import math
import strutils
import json
import nimcalcal
import db_sqlite
import tables

when not defined(js):
  import os
  import parseCsv
  import streams

import queryLocation

type city = object
  name: string
  loc: calLocationData

const SEP = ","
const SUBSEP = "|"

proc clock_to_minute(clock: calTime): string =
  result = ""
  var hour = clock.hour
  var minute = clock.minute
  if clock.second > 30:
    minute += 1
  if minute == 60:
    hour += 1
    minute = 0

  if hour < 10:
    result.add("0")
  result.add($hour)
  result.add(":")
  if minute < 10:
    result.add("0")
  result.add($minute)

proc query_gmtoffset*(tzname: string, db: DbConn): float64 =
  #let db = open(dbfile, nil, nil, nil)
  #echo "querying offset for: ", tzname
  #let row = getRow(db, sql("""select gmtoffset from localtime where zone_name = ?"), tzname)
  let row = getRow(db, sql"""select country_name country, 
                                    zone_name, 
                                    datetime(max(time_start), 'unixepoch') timestart, 
                                    gmt_offset / 3600.0 gmtoffset, 
                                    datetime(strftime('%s', 'now') + gmt_offset, 'unixepoch') localtime
                               from timezone tz, zone z, country c
                              where zone_name = ?
                                and time_start <= strftime('%s', 'now') 
                                and tz.zone_id = z.zone_id
                                and c.country_code = z.country_code
                              group by zone_name
                              order by localtime desc
                          """, tzname)
  var offset = 0.0
  try:
    offset = parseFloat(row[3])
  except:
    discard
  return offset

proc citiesFromLocation(location: string): seq[city] = 
  result = @[]
  var offset_cache = initTable[string, float64]()
  let data = queryLocation(location)
  
  echo "queried Location data:"
  echo "-".repeat(80)
  displayData(data)
  echo "-".repeat(80)

  let db = db_sqlite.open("tz.db", nil, nil, nil)

  for d in data["geonames"]:
    let name = getStr(d["name"])
    let lat = getStr(d["lat"])
    let lon = getStr(d["lng"])
    var elvt = parseFloat(getStr(d["elevation"]))
    if elvt < 0: elvt = 0.0
    let dstOffset = getFNum(d["timezone"]["dstOffset"])
    var tz_name = getStr(d["timezone"]["timezoneId"])
    if tz_name == "Asia/Rangoon":
      tz_name = "Asia/Yangon"
    var db_dstOffset: float64
    if not offset_cache.hasKey(tz_name):
      db_dstOffset = query_gmtoffset(tz_name, db)
      offset_cache[tz_name] = db_dstOffset
    else:
      db_dstOffset = offset_cache[tzname]
    echo "offset from webservice: ", dstOffset
    echo "offset from db:         ", db_dstOffset

    let c = city(name: name,
                 loc: calLocationData(latitude: parseFloat(lat),
                                      longitude: parseFloat(lon),
                                      elevation: elvt,
                                      zone: days_from_hours(db_dstOffset)))
    result.add(c)

proc process_cities(cities: seq[city]) = 
  var m = moment_from_now()
  #m = gregorian_year_end(gregorian_year_from_fixed(m.int)).float64 + time_from_moment(m)
  #m -= 4

  echo "current Date and Time: ", nimtime_from_moment(m)
  echo "universal Time:        ", gregorian_from_fixed(m.int), " ", `$`(clock_from_moment(m))[0..7]

  let lph = lunar_phase(m)
  var lph_p: float64
  if lph > 180.0:
    lph_p = round((lph - 180.0) / 180.0 * 100.0, 1)
  else:
    lph_p = round(lph / 180.0 * 100.0, 1)
  if lph <= 180.0:
    echo "Lunar phase:           ", lph_p, "% waxing"
    echo "next Full Moon:        ", nimtime_from_moment(lunar_phase_at_or_after(FULL, m))
    echo "next New  Moon:        ", nimtime_from_moment(lunar_phase_at_or_after(NEW, m))
  else:
    echo "Lunar phase:           ", lph_p, "% waning"
    echo "next New  Moon:        ", nimtime_from_moment(lunar_phase_at_or_after(NEW, m))
    echo "next Full Moon:        ", nimtime_from_moment(lunar_phase_at_or_after(FULL, m))

  echo "-".repeat(80)

  for c in cities:
    var no_sunrise = false
    var no_sunset = false
    var no_moonrise = false
    var no_moonset = false

    block a:
      let llen = len($c.loc)
      echo ""
      echo "=".repeat(llen)
      echo c.name
      echo c.loc
      var ml = standard_from_universal(m, c.loc)
      echo "Local Time:     ", gregorian_from_fixed(ml.int), " ", clock_from_moment(ml)
      echo "solar azimuth:  ", round(solar_azimuth(m, c.loc), 2)
      echo "solar altitude: ", round(solar_altitude(m, c.loc), 2)
      echo "-".repeat(llen)
      ml = ml.int.float64

      let sr = try:
                universal_from_standard(sunrise(ml, c.loc), c.loc)
               except: 
                no_sunrise = true
                -1
      let ss = try:
                universal_from_standard(sunset(ml, c.loc), c.loc)
               except:
                no_sunset = true
                -1
      let mr = try: 
                universal_from_standard(moonrise(ml, c.loc), c.loc) 
               except: 
                try:
                  universal_from_standard(moonrise(ml+1, c.loc), c.loc)
                except:
                  no_moonrise = true
                  -1

      let ms = try:
                universal_from_standard(moonset(ml, c.loc), c.loc)
               except:
                try:
                  universal_from_standard(moonset(ml+1, c.loc), c.loc)
                except:
                  no_moonrise = true
                  -1

      var az_sr, az_ss, az_mr, az_ms: float64
      if not no_sunrise:
        az_sr = solar_azimuth(sr, c.loc)
      if not no_sunset:
        az_ss = solar_azimuth(ss, c.loc)
      if not no_moonrise:
        az_mr = lunar_azimuth(mr, c.loc)
      if not no_moonset:
        az_ms = lunar_azimuth(ms, c.loc)

      if no_sunrise:
        echo "sunrise   no"
      else:
        echo "sunrise   ", gregorian_from_fixed(standard_from_universal(sr, c.loc).int), " ", 
                           clock_to_minute(clock_from_moment(standard_from_universal(sr, c.loc))), 
              " azimuth ", round(az_sr, 0).int 
      if no_sunset:
        echo "sunset    no"
      else:
        echo "sunset    ", gregorian_from_fixed(standard_from_universal(ss, c.loc).int), " ", 
                           clock_to_minute(clock_from_moment(standard_from_universal(ss, c.loc))), 
              " azimuth ", round(az_ss, 0).int
      if no_sunrise or no_sunset:
        let sa = solar_altitude(midday(m.int.float64, c.loc), c.loc)
        if sa > 0:
          echo "daylength all day "
          no_moonrise = true
          no_moonset = true
        else:
          echo "daylength null "
      else:
        echo "daylength ", clock_to_minute(clock_from_moment(ss - sr))

      if not no_moonrise and not no_moonset:
        if abs(ms - mr) < days_from_seconds(120):
          if observed_lunar_altitude(mr, c.loc) > 0:
            echo "moon up all day"
          else:
            echo "moon down all day"
        else:
          echo "moonrise  ", gregorian_from_fixed(standard_from_universal(mr, c.loc).int), " ", 
                             clock_to_minute(clock_from_moment(standard_from_universal(mr, c.loc))), 
                " azimuth ", round(az_mr, 0).int
          echo "moonset   ", gregorian_from_fixed(standard_from_universal(ms, c.loc).int), " ",
                          clock_to_minute(clock_from_moment(standard_from_universal(ms, c.loc))),
                " azimuth ", round(az_ms, 0).int
      else:
        if no_moonrise:
          echo "moonrise  no"
        else:
          echo "moonrise  ", gregorian_from_fixed(standard_from_universal(mr, c.loc).int), " ", 
                             clock_to_minute(clock_from_moment(standard_from_universal(mr, c.loc))), 
                " azimuth ", round(az_mr, 0).int
        if no_moonset:
          echo "moonset   no"
        else:
          echo "moonset   ", gregorian_from_fixed(standard_from_universal(ms, c.loc).int), " ",
                          clock_to_minute(clock_from_moment(standard_from_universal(ms, c.loc))),
                " azimuth ", round(az_ms, 0).int

  # write_cities(cities, "cities.txt")
  #    echo "mmonrise  ", clock_from_moment(mmoonrise(m, c.loc))
  #    echo "mmonset   ", clock_from_moment(mmoonset(m, c.loc))

when isMainModule:
  when not defined(js):
    let location = paramStr(1)

    let cities = citiesFromLocation(location)
    process_cities(cities)



