import os
import strutils
import strformat
import json

import levelSystem

template withDataFile(f: File, dataFilePath: typed, mode:FileMode, body: untyped) =
  if not dataFilePath.fileExists:
    quit("Error: File does not exist: " & dataFilePath)
    
  if not open(f, dataFilePath, mode):
    quit("Error: Cannot open file: " & dataFilePath)

  try:
    body
  except IOError as e:
    quit("Fatal IO error: " & e.msg)
  except OSError as e:
    quit("Fatal OS error: " & e.msg)
  finally:
    close(f)
    

proc loadRecords*(dataFilePath: string): seq[XPOrb] {.raises: [].}=
  var f: File
  withDataFile(f, dataFilePath, fmRead):
    for line in f.lines:
      if line.isEmptyOrWhitespace:
        continue

      try:
        let orb = parseXPOrb(line)
        result.add(orb)

      except ValueError, JsonParsingError:
        quit(fmt"Error: Invalid XP record: {line}")


proc appendRecord*(orb:XPOrb, dataFilePath: string) {.raises: [].} = 
  var f: File
  withDataFile(f, dataFilePath, fmAppend):
    f.writeLine($(%orb))


when isMainModule:
  proc quit*(msg: string) = 
    raise newException(CatchableError, msg)
   
  block test_withDataFile_quits_when_file_does_not_exist:
    let madeUpFile = "sdfsdffsadfsdfsadf"
    var f: File

    doAssertRaises(CatchableError):
      withDataFile(f, madeUpFile, fmRead):
        discard

  block test_withDataFile_quits_on_when_cannot_open_file:

    let filename = ".xpModel_test_tempfile"
    try:
      var f = open(filename, fmWrite)
      f.close()

      setFilePermissions(filename, {}) # nothing permitted
    
      doAssertRaises(CatchableError):
        withDataFile(f, filename, fmRead):
          discard

    finally:
      removeFile(filename)
      echo fmt"Cleaned testing tempfile {filename}"


  echo "All tests passed in xpModel"
