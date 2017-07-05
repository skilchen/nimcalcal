# Package

version       = "0.1.0"
author        = "skilchen"
description   = "clone of pycalcal"
license       = "MIT"

srcDir        = "src"
bin           = @["nimcalcal"]

backend       = "c"

# Dependencies

requires "nim >= 0.16.0"

task tests, "Run the nimcalcal tester":
  exec "nim c -r tests/all"