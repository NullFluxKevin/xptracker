import unicode
import terminal


type
  BoxCharType {.pure.} = enum
    Horizontal,
    Vertical,
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRright,
    LeftTJunction,
    RightTJunction,
    TopTJunction,
    BottomTJunction,
    Cross

  BoxDrawingCharSet = array[BoxCharType, Rune]

  ProgressBarCharType {.pure.} = enum Empty, Filled, LeftEnd, RightEnd
  ProgressBarCharSet = array[ProgressBarCharType, Rune]

const
  BasicProgressBarCharSet*: ProgressBarCharSet = [
    Empty: "-".runeAt(0),
    Filled: "▮".runeAt(0),
    LeftEnd: "[".runeAt(0),
    RightEnd: "]".runeAt(0),
  ]

  BlockProgressBarCharSet*: ProgressBarCharSet = [
    "░".runeAt(0), "█".runeAt(0), "|".runeAt(0), "|".runeAt(0)
  ]

  SquareProgressBarCharSet*: ProgressBarCharSet = [
    "□".runeAt(0), "■".runeAt(0), "[".runeAt(0), "]".runeAt(0)
  ]

  LineProgressBarCharSet*: ProgressBarCharSet = [
    "─".runeAt(0), "━".runeAt(0), "|".runeAt(0), "|".runeAt(0)
  ]

  EmojiSquareProgressBarCharSet*: ProgressBarCharSet = [
    "⬜".runeAt(0),
    "🟩".runeAt(0),
    "[".runeAt(0),
    "]".runeAt(0),
  ]


const
  SingleBorderCharSet*: BoxDrawingCharSet = [
    Horizontal: "─".runeAt(0),
    Vertical: "│".runeAt(0),
    TopLeft: "┌".runeAt(0),
    TopRight: "┐".runeAt(0),
    BottomLeft: "└".runeAt(0),
    BottomRright: "┘".runeAt(0),
    LeftTJunction: "├".runeAt(0),
    RightTJunction: "┤".runeAt(0),
    TopTJunction: "┬".runeAt(0),
    BottomTJunction: "┴".runeAt(0),
    Cross: "┼".runeAt(0),
  ]

  RoundedBorderCharSet*: BoxDrawingCharSet = [
    Horizontal: "─".runeAt(0),
    Vertical: "│".runeAt(0),
    TopLeft: "╭".runeAt(0),
    TopRight: "╮".runeAt(0),
    BottomLeft: "╰".runeAt(0),
    BottomRright: "╯".runeAt(0),
    LeftTJunction: "├".runeAt(0),
    RightTJunction: "┤".runeAt(0),
    TopTJunction: "┬".runeAt(0),
    BottomTJunction: "┴".runeAt(0),
    Cross: "┼".runeAt(0),
  ]

  DoubleBorderCharset*: BoxDrawingCharSet = [
    Horizontal: "═".runeAt(0),
    Vertical: "║".runeAt(0),
    TopLeft: "╔".runeAt(0),
    TopRight: "╗".runeAt(0),
    BottomLeft: "╚".runeAt(0),
    BottomRright: "╝".runeAt(0),
    LeftTJunction: "╠".runeAt(0),
    RightTJunction: "╣".runeAt(0),
    TopTJunction: "╦".runeAt(0),
    BottomTJunction: "╩".runeAt(0),
    Cross: "╬".runeAt(0),
  ]


proc drawLineHorizontal*(x, y, width: int, symbol: Rune) =
  setCursorPos(x, y)
  for _ in 0 ..< width:
    stdout.write(symbol)


proc drawLineVertical*(x, y, height: int, symbol: Rune) =
  for i in 0 ..< height:
    setCursorPos(x, y + i)
    stdout.write(symbol)


proc drawSymbol*(x, y: int, symbol: Rune) =
  setCursorPos(x, y)
  stdout.write(symbol)


proc drawBox*(x, y, width, height: int, boxCharSet: BoxDrawingCharSet = RoundedBorderCharSet) =

  drawSymbol(x, y, boxCharSet[TopLeft])
  drawSymbol(x + width, y, boxCharSet[TopRight])
  drawSymbol(x, y + height, boxCharSet[BottomLeft])
  drawSymbol(x + width, y + height, boxCharSet[BottomRright])

  drawLineHorizontal(x + 1, y, width - 1, boxCharSet[Horizontal])
  drawLineHorizontal(x + 1, y + height, width - 1, boxCharSet[Horizontal])
  drawLineVertical(x, y + 1, height - 1, boxCharSet[Vertical])
  drawLineVertical(x + width, y + 1, height - 1, boxCharSet[Vertical])


proc buildProgressBar*(progression: float, length: int,
    charSet: ProgressBarCharSet = SquareProgressBarCharSet): string =

  result.add(charSet[LeftEnd])

  let filledLength = (length.toFloat * progression).toInt
  let emptyLength = length - filledLength

  result.add(charSet[Filled].repeat(filledLength))
  result.add(charSet[Empty].repeat(emptyLength))

  result.add(charSet[RightEnd])

