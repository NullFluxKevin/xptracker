# [
# Math:
# 
# xp(1 -> 2) = 200
# xp(n -> n+1) = xp(n-1 -> n) + 200
# xp(n -> n+1) = 200 * n
#
# toTotalXP(n) = xp(n-1 -> n) + xp(n-2 -> n - 1) + ... + xp(1 -> 2)
#
# toTotalXP(n) = 200 * (n-1 + n-2 + ... + 1)
# toTotalXP(n) = 200 * (n * (n-1)) / 2
# 
# toTotalXP(n) = 100 * (n * (n-1))
#
# x = 100 * (n * (n-1))
# x / 100 = n^2 - n
# 0 = n^2 - n - x/100
# [ -b ± sqrt(b² - 4ac) ] / (2a) and keep the positive root
# n = (1 + sqrt(1 + (x/25)) ) / 2
# 
# toLevel(totalXP) =  (1 + sqrt(1 + (totalXP/25)) ) / 2
#
# 
# TL;DR
# 
# XPIncrement = 200
# xp(n -> n+1) = XPIncrement * n
# toTotalXP(n) = XPIncrement * (n * (n-1)) / 2
# toLevel(totalXP) =  (1 + sqrt(1 + (totalXP/(XPIncrement / 8) ) ) / 2
# ]


import math
import times
import json
import strformat


const
  XPIncrement = 200
  ISODateTimeFormat = "yyyy-MM-dd'T'HH:mm:sszzz"


type
  XP* = range[0 .. high(int)]
  Level* = range[1 .. high(int)]
  LevelProgression* = object
    xpIntoLevel*, xpRequiredToLevelUp*: XP
    progression*: float

  XPOrb* = object
    xp*: XP
    time*: DateTime
    title*: string

proc `$`*(orb: XPOrb): string {.raises: [].} = 
  let entryTime = format(orb.time.local(), "yyyy.MM.dd")
  fmt"[{entryTime}] [{orb.xp} XP] {orb.title}"


proc `%`*(xpOrb: XPOrb): JsonNode {.raises: [].} =
  %{
    "xp": %xpOrb.xp,
    "title": %xpOrb.title,
    "time": %($xpOrb.time),
  }  


proc parseXPOrb*(serialized: string): XPOrb {.raises: [JsonParsingError, ValueError].} = 
  var xpOrbNode: JsonNode
  try:
    xpOrbNode = parseJson(serialized)
    result.xp = xpOrbNode["xp"].getInt
    result.title = xpOrbNode["title"].getStr
    let timeString = xpOrbNode["time"].getStr
    result.time = parse(timeString, ISODateTimeFormat, utc())
  except JsonParsingError as e:
    raise e
  except ValueError as e:
    raise e
  except IOError, OSError:
    quit("Unexpected Fatal Error caused by IO or OS")
  

proc initXPOrb*(xp: XP, title: string, time: DateTime=now().utc): XPOrb {.raises: [].} = 
  XPOrb(xp:xp, title: title, time: time)

  
proc toLevel*(totalXP: XP): Level {.raises: [].} =
  let fractionalLevel= (1 + sqrt(1 + (totalXP / (XPIncrement / 8).floor.toInt))) / 2
  fractionalLevel.floor.toInt


proc xpIncrementToNextLevel(currentLevel: Level): XP {.raises: [].} =
  XPIncrement * currentLevel


proc toTotalXP(level: Level): XP {.raises: [].} =
  let fractionalXP = XPIncrement * (level * (level - 1)) / 2
  fractionalXP.floor.toInt


proc levelProgression*(totalXP: XP, currentLevel: Level): LevelProgression {.raises: [].} = 
  let xpIncrementToReachNextLevel = xpIncrementToNextLevel(currentLevel)
  let totalXPToReachCurrentLevel = toTotalXP(currentLevel)

  result.xpIntoLevel = totalXP - totalXPToReachCurrentLevel
  result.xpRequiredToLevelUp = xpIncrementToReachNextLevel - result.xpIntoLevel
  result.progression = result.xpIntoLevel / xpIncrementToReachNextLevel


when isMainModule:

  block test_toLevel:
    doAssert toLevel(0) == 1
    doAssert toLevel(200) == 2
    doAssert toLevel(2225) == 5


  block test_toTotalXP:
    doAssert toTotalXP(1) == 0
    doAssert toTotalXP(2) == 200
    doAssert toTotalXP(5) == 2000
  

  block test_levelProgression:
    let currentLevel = 2
    let totalXP = 300
    let progression = LevelProgression(xpIntoLevel: 100, xpRequiredToLevelUp:  300, progression: 0.25)

    doAssert levelProgression(totalXP, currentLevel) == progression


  block test_XPOrb_json_serialization:
    let timeString = "2025-05-25T20:10:10Z"
    let time = parse(timeString, ISODateTimeFormat, utc())
    let expected = """{"xp":100,"title":"test","time":"2025-05-25T20:10:10Z"}"""

    let orb = initXPOrb(100, "test", time)

    doAssert $(%orb) == expected


  block test_parseXPOrb:
    let serialized = """{"xp":100,"title":"test","time":"2025-05-25T20:10:10Z"}"""
    let timeString = "2025-05-25T20:10:10Z"
    let time = parse(timeString, ISODateTimeFormat, utc())

    let orb = parseXPOrb(serialized)

    doAssert orb == initXPOrb(100, "test", time)


  block test_parseXPOrb_raises_ValueError:
    let invalidRecord = """{"p":100}"""

    doAssertRaises(ValueError):
      discard parseXPOrb(invalidRecord)


  block test_parseXPOrb_raises_JsonParsingError:
    let invalidJson = """"xp":100, "title" "test"""

    doAssertRaises(JsonParsingError):
      discard parseXPOrb(invalidJson)


  echo("All tests pass in levelSystem")

