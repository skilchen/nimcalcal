import httpclient
import json
import htmlparser
import streams
import xmltree
when not defined(js):
  import os
#import asyncnet, asyncdispatch, asyncfile
import strutils
import times
import math
from cgi import encodeUrl

proc getClockStr*(): string  =
  let x = epochTime()
  let y = $(x - floor(x))
  let t = times.getClockStr()
  return "$#.$#" % [t, y[2..4]]

export getClockStr

proc printf(formatstr: cstring) {.importc header:"<stdio.h>" varargs.}

proc queryLocation*(location: string): JsonNode = 
  var client = newHttpClient()
  var loc_url = "http://api.geonames.org/search?q=$1&maxRows=1&type=json&username=skilchen"  
  let location_url = loc_url % [encodeUrl(location)]
  
  var elevation_url_t = "http://api.geonames.org/srtm3?lat=$1&lng=$2&username=skilchen"
  var tz_url_t = "http://api.geonames.org/timezoneJSON?lat=$1&lng=$2&username=skilchen"
  let x = client.get(location_url)
  # echo x.status
  # for k, v in x.headers:
  #   printf("%s %-30.30s: %s\n", "test1", k, v)

  var data = parseJson(x.body)

  var geonames = data["geonames"]
  for i in mitems(geonames):
    # echo "-".repeat(80)
    # echo getStr(i["name"]), " ", getStr(i["lat"]), " ", getStr(i["lng"])
    let lat = getStr(i["lat"])
    let lng = getStr(i["lng"])
    let elevation_url = elevation_url_t % [lat, lng]
    let y = client.get(elevation_url)
    let elevation = strip($y.body)
    i["elevation"] = newJString($elevation)
    let tzd = client.get(tz_url_t % [lat, lng])
    var tzdata = parseJson(tzd.body)
    i["timezone"] = tzdata
    # echo "-".repeat(80)

  return data

proc displayData*(data: JsonNode) =
  for d in data["geonames"]:
    let name = getStr(d["name"])
    let country_c = getStr(d["countryCode"])
    let country_n = getStr(d["countryName"], "unknown")
    let population = getNum(d["population"], 0)
    let lat = getStr(d["lat"])
    let long = getStr(d["lng"])
    let elevation = getStr(d["elevation"], "blabla")
    let time = getStr(d["timezone"]["time"])
    let dst_offset = getFNum(d["timezone"]["dstOffset"])
    if d["timezone"].contains("sunrise"):
      let sunrise = getStr(d["timezone"]["sunrise"])
      let sunset = getStr(d["timezone"]["sunset"])
      printf("%s %s %s %s %s %s %s %s %s %s %s\n", name, country_c, country_n, $population, lat, long, elevation, time, $dst_offset, sunrise, sunset)
    else:
      printf("%s %s %s %s %s %s %s %s %s %s %s\n", name, country_c, country_n, $population, lat, long, elevation, time, $dst_offset, "no sunrise", "no sunset")

when isMainModule:
  when not defined(js):
    let location = paramStr(1)
  
    let data = queryLocation(location)
    echo pretty(data)
    echo "-".repeat(80)
    displayData(data)