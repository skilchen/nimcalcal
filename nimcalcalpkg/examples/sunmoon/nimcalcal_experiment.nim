import times
import math
import strutils
import nimcalcal
from querySunMoonTimes import query_gmtoffset
from algorithm import reverse

when not defined(js):
  import os
  import parseCsv
  import streams
  import db_sqlite
  import tables

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

proc commify_number(n: string): string =
  var nstr = n
  let parts = nstr.split(".")
  result = ""
  for i in 0..nstr.high:
    if i mod 3 == 0 and i > 0:
      result.add("'")
    result.add(nstr[nstr.high - i])
  reverse(result)
  return result

when not defined(js):
  proc write_cities(cities: seq[city], output_file: string) = 
    let ofp = open(output_file, fmWrite)
    let sep = ","
    let subsep = "|"
    for c in cities:
      var line = ""
      line.add(c.name)
      line.add(sep)
      let lat = angle_from_degrees(c.loc.latitude)
      let lon = angle_from_degrees(c.loc.longitude)
      let zone = clock_from_moment(c.loc.zone)

      line.add($lat[0] & SUBSEP & $lat[1] & SUBSEP & $lat[2])
      line.add(sep)
      line.add($lon[0] & SUBSEP & $lon[1] & SUBSEP & $lon[2])
      line.add(sep)
      line.add($c.loc.elevation)
      line.add(sep)
      line.add($zone.hour & SUBSEP  & $zone.minute)
      line.add("\n")
      ofp.write(line)
    ofp.close()

  proc read_cities_1(input_file: string): seq[city] =
    result = @[]
    var offset_cache = initTable[string, float64]()
    var s: FileStream 
    if input_file == "-":
      s = newFileStream(stdin)
    else:
      s = newFileStream(input_file)
    if s == nil: quit("can't read: " & input_file)
    var x: CsvParser
    open(x, s, input_file, separator=',')
    let db = db_sqlite.open("tz.db", nil, nil, nil)

    while readRow(x):
      let elevation = if x.row[6] == "": 0.0 else: parseFloat(x.row[6])
      let offset_f = parseFloat(x.row[8])
      var tz_name = x.row[7]
      if tz_name == "Asia/Rangoon":
        tz_name = "Asia/Yangon"

      var offset_db: float64
      if not offset_cache.hasKey(tz_name):
        offset_db = query_gmtoffset(tz_name, db)
        offset_cache[tz_name] = offset_db
        if `mod`(offset_f,1.0) != 0 or `mod`(offset_db, 1.0) != 0:
          echo  tz_name, " has minute offset: ", offset_f, " ", offset_db
      else:
        offset_db = offset_cache[tz_name]
      if offset_f != offset_db:
        echo x.row[7]
        echo "offset from file: ", offset_f
        echo "offset from db:   ", offset_db
      var   c: city
      try:
        c = city(name: x.row[1] & ", " & x.row[4] & " (" & commify_number(x.row[5]) & ") " & x.row[7],
                 loc: calLocationData(latitude: parseFloat(x.row[2]),
                                      longitude: parseFloat(x.row[3]),
                                      elevation: elevation,
                                      zone: days_from_hours(offset_db)))
        result.add(c)        
      except:
        stderr.write($x.row & "\n")
        continue

    close(x)
    close(s)

  proc read_cities(input_file: string): seq[city] = 
    result = @[]
    let data = readFile(input_file)
    let lines = data.splitLines()
    for line in lines:
      let flds = line.split(SEP)
      if len(flds) < 5:
        continue
      let lat = flds[1].split(SUBSEP)
      let lon = flds[2].split(SUBSEP)
      let zone = flds[4].split(SUBSEP)
      var c = city(name: flds[0],
                   loc: calLocationData(latitude: angle(parseFloat(lat[0]), parseFloat(lat[1]), parseFloat(lat[2])),
                                        longitude: angle(parseFloat(lon[0]), parseFloat(lon[1]), parseFloat(lon[2])),
                                        elevation: parseFloat(flds[3]),
                                        zone: time_from_clock(calTime(hour: parseInt(zone[0]), 
                                                                      minute: if len(zone) > 1: parseInt(zone[1]) else: 0))))
      result.add(c)
    return result


when defined(js):
  proc load_predefined_cities(): seq[city] =
    var cities: seq[city] = @[]
    var capetown = location(-angle(33,55,0),angle(18,25,0), 25, days_from_hours(2))
    var paris = PARIS
    paris.zone = days_from_hours(2)

    var bruxelles = BRUXELLES
    bruxelles.zone = days_from_hours(2)

    var tehran = TEHRAN
    tehran.zone = days_from_hours(4.5)

    var urbana = URBANA
    urbana.zone = days_from_hours(-5)

    var greenwich = GREENWHICH
    greenwich.zone = days_from_hours(1)

    var tokyo = calLocationData(latitude: angle(35,41,0),
                                longitude: angle(139, 42, 0),
                                elevation: 5,
                                zone: days_from_hours(9))
    var anchorage = calLocationData(latitude: angle(61, 13, 2),
                                    longitude: angle(-149, -51, -47),
                                    elevation: 36,
                                    zone: days_from_hours(-8))

    var alert = calLocationData(latitude: angle(82, 30, 0),
                                longitude: angle(-62, -20, 0),
                                elevation: 30,
                                zone: days_from_hours(-4))

    var pontianak = calLocationData(latitude: angle(0, 1, 0),
                                    longitude: angle(109, 20, 0),
                                    elevation: 0,
                                    zone: days_from_hours(7))
    var turin = calLocationData(latitude: angle(45, 4, 0),
                                longitude: angle(7, 42, 0),
                                elevation: 239,
                                zone: days_from_hours(2))
    var coihaique = calLocationData(latitude: angle(-45, -34, 0),
                                    longitude: angle(-72, -4, 0),
                                    elevation: 302,
                                    zone: days_from_hours(-3))
    var concordia = calLocationData(latitude: angle(-75, -6, 0),
                                    longitude: angle(-123, -20, 0),
                                    elevation: 3233,
                                    zone: days_from_hours(8))
    var rabi = calLocationData(latitude: angle(-16, 30, 0),
                               longitude: angle(180, 0, 0),
                               elevation: 433,
                               zone: days_from_hours(12))
      
    cities.add(city(name: "Paris", loc: paris))
    cities.add(city(name: "Kapstadt", loc: capetown))
    cities.add(city(name: "Bruxelles", loc: bruxelles))
    cities.add(city(name: "Tehran", loc: tehran))
    cities.add(city(name: "Urbana", loc: urbana))
    cities.add(city(name: "Greenwich", loc: greenwich))
    cities.add(city(name: "Tokyo", loc: tokyo))
    cities.add(city(name: "Anchorage", loc: anchorage))
    cities.add(city(name: "Alert", loc: alert))
    cities.add(city(name: "Pontianak", loc: pontianak))
    cities.add(city(name: "Torino", loc: turin))
    cities.add(city(name: "Coihaique", loc: coihaique))
    cities.add(city(name: "Concordia Station", loc: concordia))
    cities.add(city(name: "Rabi Island", loc: rabi))

    return cities

proc process_cities(filename: string) = 
  var cities: seq[city]
  when not defined(js):
    cities = read_cities_1(filename)
  else:
    cities = load_predefined_cities()

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
  var filename: string
  when not defined(js):
    filename = paramStr(1)
  else:
    filename = ""

  process_cities(filename)



