import parseopt
import os
import sequtils
import strutils
import terminal
import sugar
import math
import strformat
import json

import levelSystem
import tuiKit
import xpModel

const Version = "v0.1.0"

const HelpMessage = fmt"""
XP Tracker
{Version}

    Every progression is worth tracking.
    Keep improving.

DATA PATH:
    ~/.local/share/xptracker

USAGE:
    xptracker [FLAGS]

FLAGS:
  -a="AMOUNT|SUMMARY"    Add AMOUNT XP with SUMMARY.
                         Quotes are strictly required.

  -l[=N]                 Show the last N entries.
                         N is a positive integer, default to 1.

  -h                     Show help message
  -v                     Show version
"""


const DataDirPath = ".local/share/xptracker"
const DataFileName = "xp.dat"


proc showLevelInfo(orbs: openArray[XPOrb]) =
  
  let totalXP = orbs.map((o: XPOrb) -> XP => o.xp).sum

  let currLevel = toLevel(totalXP)
  echo fmt"Lv. {currLevel} | {totalXP} XP"
  let progress = levelProgression(totalXP, currLevel)

  let progressBar = buildProgressBar(progress.progression, 30)
  echo fmt"Next: {progressBar} {(progress.progression * 100).toInt}% ({progress.xpIntoLevel}/{progress.xpRequiredToLevelUp + progress.xpIntoLevel} XP)"  


proc animatedLevelInfo(orbs: openArray[XPOrb], newOrb: XPOrb) =

  var
    totalXP = orbs.map((o: XPOrb) -> XP => o.xp).sum
    currLevel = toLevel(totalXP)
    newLevel = toLevel(totalXP + newOrb.xp)

    levelInfo:string

  if currLevel != newLevel:
    levelInfo = fmt"Lv. {currLevel} -> {newLevel} 🔥"
  else:
    levelInfo = fmt"Lv. {currLevel}"

  var chunkCount = 50
  if chunkCount >= newOrb.xp:
    chunkCount = newOrb.xp
    

  let chunk = newOrb.xp div chunkCount
  let remaining = newOrb.xp mod chunkCount

  var chunks = collect(newSeq):
    for i in 0 ..< chunkCount:
      chunk

  chunks.add(remaining)

  var addedXP = 0
  for i, chunk in chunks:
    totalXP += chunk
    addedXP += chunk
    currLevel = toLevel(totalXP)

    stdout.styledWriteLine(fgWhite, levelInfo, fmt" | {totalXP}",fgGreen, fmt" + {newOrb.xp - addedXP}", fgWhite, " XP")

    let progress = levelProgression(totalXP, currLevel)

    let progressBar = buildProgressBar(progress.progression, 30)
    echo fmt"Next: {progressBar} {(progress.progression * 100).toInt}% ({progress.xpIntoLevel}/{progress.xpRequiredToLevelUp + progress.xpIntoLevel} XP)"  

    sleep 30
    cursorUp 1
    eraseLine()
    cursorUp 1
    eraseLine()

  showLevelInfo(@orbs & @[newOrb])



  
proc getDataFilePath(): string =
  when defined(release):
    let userHome = getHomeDir()
    let AbsoluteDataDirPath = userHome / DataDirPath

    if not dirExists(AbsoluteDataDirPath):
      createDir(AbsoluteDataDirPath)

    result = AbsoluteDataDirPath / DataFileName

  else:
    result = absolutePath(DataFileName)


proc unknownUsage() =
  echo "Unknown usage\n"
  echo HelpMessage
  quit()

proc parseXPArg(xpArg: string): XPOrb = 
  const Usage = """USAGE: xptracker -a="AMOUNT|SUMMARY""""

  let parts = xpArg.split("|")

  if len(parts) != 2:
    echo "Error: Invalid argument value"
    echo Usage
    quit()

  let xpArg = parts[0].strip
  let summaryArg = parts[1].strip

  if len(xpArg) == 0 or len(summaryArg) == 0:
    echo "Error: Invalid argument value"
    echo Usage
    quit()
  
  var xp: XP
  try:
    xp = xpArg.parseInt

  except ValueError:
    echo "Error: AMOUNT should be an integer"
    echo Usage
    quit()

  result = initXPOrb(xp, summaryArg)
 

when isMainModule:

  let dataPath = getDataFilePath()

  if not dataPath.fileExists:
    echo fmt"Creating new XP data file: {dataPath}"
    let f = open(dataPath, FileMode.fmWrite)
    f.close()
    echo "XP data file created."

  var orbs = loadRecords(dataPath)

  for kind, key, value in getopt():
    case kind:
    of cmdShortOption:
      case key:
      of "v":
        echo fmt"XP Tracker {Version}"
        quit()

      of "h":
        echo HelpMessage
        quit()

      of "a": 
        let orb = parseXPArg(value)
        appendRecord(orb, dataPath)
        animatedLevelInfo(orbs, orb)
        quit()

      of "l":
        var count: Positive = 1
        let countString = value.strip

        if len(countString) != 0:
          try:
            count = countString.parseInt()
          except ValueError, RangeDefect:
            echo fmt"Invalid input. Default to showing the last entry."

        for index, orb in orbs[^count .. high(orbs)]:
          echo $orb

        quit()

      else:
        unknownUsage()

    of cmdLongOption, cmdArgument, cmdEnd: 
      unknownUsage()

  showLevelInfo(orbs)
    
