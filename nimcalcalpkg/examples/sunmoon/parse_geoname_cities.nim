import parsecsv
import streams
import strutils
import os
import tables

const SEP = ","

proc load_timezone_offsets(timezonefile: string): TableRef[string, float] =
  var s = newFileStream(timezonefile)
  if s == nil: quit("can't read: " & timezonefile)
  var tzTable = newTable[string, float]()
  var x: CsvParser
  open(x, s, timezonefile, separator='\t')
  discard readRow(x)
  while readRow(x):
    tzTable[x.row[1]] = parseFloat(x.row[3])
  close(x)
  close(s)
  return tzTable

proc parse_geoname_cities(infilename, outfilename: string, tzTable: TableRef[string, float]) =
  var s = newFileStream(infilename)
  if s == nil: quit("can't read " & infilename)
  var ostr = newFileStream(outfilename, fmWrite)
  if ostr == nil: quit("can't write to " & outfilename)
  var x: CsvParser
  open(x, s, infilename, separator = '\t', quote='\0')
  while true:
    try:
      if not readRow(x, columns=19):
        break
      if len(x.row) < 18:
        echo "line has not enough fields: ", x.processedRows()
        continue
      var oline = ""
      # id
      oline.add(x.row[0])
      oline.add(SEP)
      # name
      oline.add(x.row[2].replace(',',' '))
      oline.add(SEP)
      # latitude
      oline.add(x.row[4])
      oline.add(SEP)
      # longitude
      oline.add(x.row[5])
      oline.add(SEP)
      # country code
      oline.add(x.row[8])
      oline.add(SEP)
      # population
      oline.add(x.row[14])
      oline.add(SEP)
      # elevation
      oline.add(x.row[15])
      oline.add(SEP)
      # timezone name
      let tzname = x.row[17]
      oline.add(tzname)
      oline.add(SEP)
      # timezone offset
      if tzTable.hasKey(tzname):
        oline.add($tzTable[tzname])
      oline.add("\n")
      ostr.write(oline)
    except:
      echo getCurrentExceptionMsg()
  x.close()
  s.close()
  ostr.close()

when isMainModule:
  let infilename = paramStr(1)
  let outfilename = paramStr(2)

  let tzTable = load_timezone_offsets("timeZones.txt")
  parse_geoname_cities(infilename, outfilename, tzTable)
  

