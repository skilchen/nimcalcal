# Package

version       = "0.1.0"
author        = "skilchen"
description   = "clone of pycalcal"
license       = "MIT"

bin           = @["nimcalcal"]

backend       = "c"

# Dependencies

requires "nim >= 0.17.0"
requires "strfmt >= 0.8.5"

task tests, "Run the nimcalcal tester":
  exec "nim c -r nimcalcalpkg/tests/all"

task tests_js, "Run the nimcalcal tester using the js backend":
    exec "nim js -d:nodejs --threads:off -r nimcalcalpkg/tests/all"
