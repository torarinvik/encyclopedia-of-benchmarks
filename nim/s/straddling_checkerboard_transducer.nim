const MaxInput = 97
const MaxText = 64
const BoardSize = 30
const MaxOutput = 128

proc parseBoard(input: ptr UncheckedArray[int64], length: csize_t,
    holeA: var int, holeB: var int, textLength: var int, mode: var int64): bool =
  if input == nil or length < 32 or length > MaxInput: return false
  mode = input[0]
  if mode != 0 and mode != 1: return false
  var holes = 0
  for position in 0 ..< BoardSize:
    let value = input[1 + position]
    if position < 10 and value == 0:
      if holes == 0: holeA = position
      elif holes == 1: holeB = position
      inc holes
      continue
    if value < 32 or value > 126: return false
    for prior in 0 ..< position:
      if input[1 + prior] == value: return false
  if holes != 2: return false
  let count = input[31]
  if count < 0 or count > MaxText: return false
  textLength = int(count)
  int(length) == 32 + textLength

proc findSymbol(input: ptr UncheckedArray[int64], value: int64): int =
  for position in 0 ..< BoardSize:
    if input[1 + position] != 0 and input[1 + position] == value: return position
  -1

proc measureDecode(input: ptr UncheckedArray[int64], textLength, holeA,
    holeB: int, outputLength: var int): bool =
  var index = 0
  while index < textLength:
    let value = input[32 + index]
    if value < int64(ord('0')) or value > int64(ord('9')): return false
    let column = int(value - int64(ord('0')))
    if input[1 + column] != 0:
      inc outputLength
      inc index
      continue
    if (column != holeA and column != holeB) or index + 1 >= textLength: return false
    let next = input[32 + index + 1]
    if next < int64(ord('0')) or next > int64(ord('9')): return false
    inc outputLength
    index += 2
  true

proc straddlingCheckerboardTransducer*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "straddling_checkerboard_transducer".} =
  var holeA = -1
  var holeB = -1
  var textLength = 0
  var mode = -1'i64
  if not parseBoard(input, length, holeA, holeB, textLength, mode): return -1
  var resultLength = 0
  if mode == 0:
    for index in 0 ..< textLength:
      let position = findSymbol(input, input[32 + index])
      if position < 0: return -1
      resultLength += (if position < 10: 1 else: 2)
  elif not measureDecode(input, textLength, holeA, holeB, resultLength):
    return -1
  if resultLength > MaxOutput: return -1
  if output == nil or outputCapacity < csize_t(resultLength): return -2
  if mode == 0:
    var outIndex = 0
    for index in 0 ..< textLength:
      let position = findSymbol(input, input[32 + index])
      if position < 10:
        output[outIndex] = uint8(ord('0') + position)
        inc outIndex
      else:
        let rowDigit = (if position < 20: holeA else: holeB)
        output[outIndex] = uint8(ord('0') + rowDigit)
        output[outIndex + 1] = uint8(ord('0') + position mod 10)
        outIndex += 2
  else:
    var index = 0
    var outIndex = 0
    while index < textLength:
      let column = int(input[32 + index] - int64(ord('0')))
      if input[1 + column] != 0:
        output[outIndex] = uint8(input[1 + column])
        inc index
      else:
        let row = (if column == holeA: 1 else: 2)
        let nextColumn = int(input[32 + index + 1] - int64(ord('0')))
        output[outIndex] = uint8(input[1 + row * 10 + nextColumn])
        index += 2
      inc outIndex
  int64(resultLength)
