const CodeStates = 6561
const MaxStates = 78732
type FrontierCodes = array[4, int]

proc cellColor(code: int): int =
  if code == 0: -1 else: (if code <= 4: 0 else: 1)

proc advanceFrontier(inputCodes: FrontierCodes, closed, diagonal, color,
                     row, column: int, outputCodes: var FrontierCodes,
                     outputClosed, outputDiagonal: var int): bool =
  if (closed and (1 shl color)) != 0: return false
  let above = inputCodes[column]
  let left = if column == 0: 0 else: inputCodes[column - 1]
  if row != 0 and column != 0 and cellColor(above) == color and
      cellColor(left) == color and diagonal == color + 1:
    return false

  outputCodes = inputCodes
  outputCodes[column] = 0
  let aboveColor = cellColor(above)
  let aboveLabel = if aboveColor == color: (if color == 0: above else: above - 4) else: 0
  let leftLabel = if cellColor(left) == color: (if color == 0: left else: left - 4) else: 0
  var chosenLabel = if aboveLabel != 0: aboveLabel else: leftLabel
  if aboveLabel != 0 and leftLabel != 0 and aboveLabel != leftLabel:
    for slot in 0 ..< 4:
      if color == 0 and outputCodes[slot] == leftLabel: outputCodes[slot] = aboveLabel
      if color == 1 and outputCodes[slot] == 4 + leftLabel: outputCodes[slot] = 4 + aboveLabel
    chosenLabel = aboveLabel
  if chosenLabel == 0:
    var maximum = 0
    for code in outputCodes:
      if cellColor(code) == color:
        let label = if color == 0: code else: code - 4
        if label > maximum: maximum = label
    chosenLabel = maximum + 1
  outputCodes[column] = if color == 0: chosenLabel else: 4 + chosenLabel

  outputClosed = closed
  if above != 0 and aboveColor != color:
    var oldStillPresent = false
    var otherSameColor = false
    for code in outputCodes:
      if code == above: oldStillPresent = true
      if cellColor(code) == aboveColor and code != above: otherSameColor = true
    if not oldStillPresent:
      if otherSameColor: return false
      outputClosed = closed or (1 shl aboveColor)

  var mapping: array[9, int]
  var nextBlack = 0
  var nextWhite = 0
  for slot in 0 ..< 4:
    let code = outputCodes[slot]
    if code == 0: continue
    if code <= 4:
      if mapping[code] == 0:
        inc nextBlack
        mapping[code] = nextBlack
      outputCodes[slot] = mapping[code]
    else:
      let key = code
      if mapping[key] == 0:
        inc nextWhite
        mapping[key] = 4 + nextWhite
      outputCodes[slot] = mapping[key]
  outputDiagonal = if aboveColor < 0: 0 else: aboveColor + 1
  return true

proc encodeState(codes: FrontierCodes, closed, diagonal: int): int =
  let powers = [1, 9, 81, 729]
  var codeKey = 0
  for slot in 0 ..< 4: codeKey += codes[slot] * powers[slot]
  (closed * 3 + diagonal) * CodeStates + codeKey

proc connectivity_aware_plug_dp_binary_grid_colorings*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "connectivity_aware_plug_dp_binary_grid_colorings".} =
  if input == nil or length != 2: return -1
  let rowsValue = input[0]
  let columnsValue = input[1]
  if rowsValue < 2 or rowsValue > 4 or columnsValue < 2 or columnsValue > 4: return -1
  let rows = int(rowsValue)
  let columns = int(columnsValue)

  var dp, next: array[MaxStates, int64]
  dp[0] = 1
  for cell in 0 ..< rows * columns:
    let row = cell div columns
    let column = cell mod columns
    for state in 0 ..< MaxStates: next[state] = 0
    for state in 0 ..< MaxStates:
      if dp[state] == 0: continue
      var codeKey = state mod CodeStates
      let flags = state div CodeStates
      let diagonal = flags mod 3
      let closed = flags div 3
      var codes: FrontierCodes
      for slot in 0 ..< 4:
        codes[slot] = codeKey mod 9
        codeKey = codeKey div 9
      for color in 0 ..< 2:
        var outputCodes: FrontierCodes
        var outputClosed = 0
        var outputDiagonal = 0
        if advanceFrontier(codes, closed, diagonal, color, row, column,
                           outputCodes, outputClosed, outputDiagonal):
          let destination = encodeState(outputCodes, outputClosed, outputDiagonal)
          next[destination] += dp[state]
    dp = next

  var total = 0'i64
  for state in 0 ..< MaxStates:
    if dp[state] == 0: continue
    var codeKey = state mod CodeStates
    let closed = (state div CodeStates) div 3
    var seenBlack: array[5, bool]
    var seenWhite: array[5, bool]
    var blackComponents = 0
    var whiteComponents = 0
    for _ in 0 ..< 4:
      let code = codeKey mod 9
      codeKey = codeKey div 9
      if code >= 1 and code <= 4 and not seenBlack[code]:
        seenBlack[code] = true
        inc blackComponents
      elif code >= 5 and code <= 8 and not seenWhite[code - 4]:
        seenWhite[code - 4] = true
        inc whiteComponents
    if ((closed and 1) != 0 and blackComponents == 0 or
        (closed and 1) == 0 and blackComponents == 1) and
        ((closed and 2) != 0 and whiteComponents == 0 or
        (closed and 2) == 0 and whiteComponents == 1):
      total += dp[state]
  return total
