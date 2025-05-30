import os
import strutils
import strformat
import json

import levelSystem
import xpView


const releaseDataDirPath = ".local/share/xptracker"
const dataFileName = "xp.dat"

  
proc getDataFilePath*(): string {.raises: [].} =
  when defined(release):
    let userHome = getHomeDir()
    let absoluteDataDirPath = userHome / releaseDataDirPath

    if not dirExists(absoluteDataDirPath):
      try:
        createDir(absoluteDataDirPath)
      except OSError,IOError:
        quit("Fatal Error: Failed to create XP file directory")

    result = absoluteDataDirPath / dataFileName

  else:
    try:
      let root = getCurrentDir()
      result = absolutePath(dataFileName, root)
    except OSError:
      quit("Fatal OS Error")

    except ValueError:
      discard """Manually provide root which will always be absolute, so will never raise ValueError."""


proc createDataFileIfDoesNotExist*() {.raises: [].}= 
  let dataPath = getDataFilePath()

  if not dataPath.fileExists:
    info fmt"Creating new XP data file: {dataPath}"
    var f: File
    try:
      if not open(f, dataPath, fmWrite):
        error fmt"Failed to create XP data file: {dataPath}"
    finally:
      close(f)

    info "XP data file created."


template withDataFile*(f: File, dataFilePath: typed, mode:FileMode, body: untyped) =
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
    

proc loadRecords*(): seq[XPOrb] {.raises: [].}=
  let dataFilePath = getDataFilePath()
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


proc appendRecord*(orb:XPOrb) {.raises: [].} = 
  let dataFilePath = getDataFilePath()
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
