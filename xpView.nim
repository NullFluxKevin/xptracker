import os
import terminal
import math
import sugar
import sequtils
import strformat

import tuiKit
import levelSystem


const
  progressBarLength = 30

  # Animation
  durationPerFrame = 30
  framesCount = 50

proc systemMessage(msgTypeColor: ForegroundColor, msgType, msg: string) {.raises: [].} =
  try:
    stdout.styledWriteLine(msgTypeColor, msgType, " ", resetStyle, msg)
  except IOError:
    quit("Fatal IO Error")
  
proc error*(msg: string) {.raises:[].} = 
  systemMessage(fgRed, "[ ERROR ]", msg)


proc warn*(msg: string) {.raises:[].} = 
  systemMessage(fgYellow, "[ WARN ]", msg)
  
proc info*(msg: string) {.raises:[].} = 
  systemMessage(fgGreen, "[ INFO ]", msg)


proc listEntries*(orbs: openArray[XPOrb]) {.raises:[].}= 
  for orb in orbs:
    echo $orb


proc showLevelInfo*(orbs: openArray[XPOrb]) {.raises: [].} =
  let totalXP = orbs.map((o: XPOrb) -> XP => o.xp).sum

  let currLevel = toLevel(totalXP)
  echo fmt"Lv. {currLevel} | {totalXP} XP"

  let progress = levelProgression(totalXP, currLevel)

  let progressBar = buildProgressBar(progress.progression, progressBarLength)
  let percentage = (progress.progression * 100).toInt
  let xpRequiredToLevelUp = progress.xpRequiredToLevelUp + progress.xpIntoLevel

  echo fmt"Next: {progressBar} {percentage}% ({progress.xpIntoLevel}/{xpRequiredToLevelUp} XP)"  


proc addingXPAnimation*(orbs: openArray[XPOrb], newOrb: XPOrb) {.raises:[].} =
  try:
    hideCursor()
  except IOError:
    discard """Can't hide cursor, no big deal"""

  var
    totalXP = orbs.map((o: XPOrb) -> XP => o.xp).sum
    currLevel = toLevel(totalXP)
    newLevel = toLevel(totalXP + newOrb.xp)

    levelInfo:string

  let hasLeveledUp = currLevel != newLevel

  if hasLeveledUp:
    levelInfo = fmt"⏫ Lv.{currLevel} ⟶ {newLevel}"
  else:
    levelInfo = fmt"Lv. {currLevel}"

  var chunkCount = framesCount
  if chunkCount >= newOrb.xp:
    chunkCount = newOrb.xp
    
  let chunk = newOrb.xp div chunkCount
  let remaining = newOrb.xp mod chunkCount

  var chunks = collect(newSeq):
    for i in 0 ..< chunkCount:
      chunk

  chunks.add(remaining)

  try:
    var addedXP = 0
    for i, chunk in chunks:
      totalXP += chunk
      addedXP += chunk
      currLevel = toLevel(totalXP)

      let isLastIteration = i == high(chunks)

      let progressBarSymbol = if isLastIteration: "Next:" else: "⏫"

      if not isLastIteration:
        stdout.styledWriteLine(fgWhite, levelInfo, fmt" | {totalXP} XP", styleItalic, fgGreen, fmt" + {newOrb.xp - addedXP}")
      else:
        levelInfo = fmt"Lv. {newLevel}"
        stdout.styledWriteLine(fgWhite, levelInfo, fmt" | {totalXP} XP")

      let progress = levelProgression(totalXP, currLevel)

      let progressBar = buildProgressBar(progress.progression, progressBarLength)
      let percentage = (progress.progression * 100).toInt
      let totalLevelUpXP = progress.xpRequiredToLevelUp + progress.xpIntoLevel
      echo fmt"{progressBarSymbol} {progressBar} {percentage}% ({progress.xpIntoLevel}/{totalLevelUpXP} XP)"  

      sleep durationPerFrame

      if not isLastIteration:
        cursorUp 1
        eraseLine()
        cursorUp 1
        eraseLine()

    stdout.styledWriteLine(styleBright, fgYellow, fmt"🎉 XP GAINED: +{newOrb.xp}")

    if hasLeveledUp:
      stdout.styledWriteLine(styleBlink,fgYellow, fmt"🎖️LEVEL UP")

    showCursor()

  except IOError:
    quit("Fatal IO Error")

