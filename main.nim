import parseopt
import os
import strutils
import math
import strformat

import levelSystem
import xpModel
import xpView


const version = "v0.1.0"

const helpMessage = fmt"""
XP Tracker
{version}

    Every progression is worth tracking.
    Keep improving.

USAGE:
    xptracker [FLAGS]

FLAGS:
  -a="AMOUNT|SUMMARY"    Add AMOUNT XP with SUMMARY.
                         Quotes are strictly required.

  -l[=N]                 Show the last N entries.
                         N is a positive integer, default to 1.

  -h                     Show help message.
  -v                     Show version.
  -s                     Show save file path.
"""


proc showHelp() {.raises: [].} = 
  echo helpMessage


proc showUnknownUsageError() {.raises: [].} =
  error "Unknow usage"
  showHelp()


proc quitOnInvalidArg(errorMsg: string, usage: string) {.raises: [].} = 
  error errorMsg
  info usage
  quit()
 

proc parseXPArg(xpArg: string): XPOrb {.raises:[].} = 
  const usage = """USAGE: xptracker -a="AMOUNT|SUMMARY""""

  let parts = xpArg.split("|")

  if len(parts) != 2:
    quitOnInvalidArg("Invalid argument value", usage)

  let xpArg = parts[0].strip
  let summaryArg = parts[1].strip

  if len(xpArg) == 0 or len(summaryArg) == 0:
    quitOnInvalidArg("Invalid argument value", usage)
  
  var xp: XP
  try:
    xp = xpArg.parseInt

  except ValueError:
    quitOnInvalidArg("AMOUNT should be an integer", usage)

  result = initXPOrb(xp, summaryArg)
 

proc main() =
  createDataFileIfDoesNotExist()

  var orbs = loadRecords()

  if paramCount() == 0:
    showLevelInfo(orbs)
    quit()
    
  for kind, key, value in getopt():
    case kind:
    of cmdShortOption:
      case key:
      of "v":
        echo fmt"XP Tracker {version}"

      of "h":
        showHelp()

      of "s":
        echo getDataFilePath()

      of "a": 
        let orb = parseXPArg(value)
        appendRecord(orb)
        addingXPAnimation(orbs, orb)

      of "l":
        if len(orbs) == 0:
          quitOnInvalidArg(
            "XP data file is empty",
            """Add records first with: xptracker -a="AMOUNT|SUMMARY""""
          )

        var count: Positive = 1
        let countString = value.strip

        if len(countString) != 0:
          try:
            count = countString.parseInt
          except ValueError, RangeDefect:
            warn "Invalid input. Default to showing the last entry."

        count = min(count, len(orbs))

        listEntries(orbs[^count .. high(orbs)])

      else:
        showUnknownUsageError()

    of cmdLongOption, cmdArgument, cmdEnd: 
      showUnknownUsageError()


when isMainModule:
  main()
