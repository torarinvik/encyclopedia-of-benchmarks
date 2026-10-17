const MaxInputLength = 16_384

proc isTriangleScore(score: int64): bool =
  for n in 1'i64 .. 100'i64:
    if n * (n + 1) div 2 == score:
      return true
  false

proc countFirstLine(bytes: openArray[uint8]): int64 =
  var lineEnd = bytes.len
  for index, byte in bytes:
    if byte == 13 or byte == 10:
      lineEnd = index
      break
  var count = 0'i64
  var tokenStart = 0
  var position = 0
  while position <= lineEnd:
    if position != lineEnd and bytes[position] != uint8(ord(',')):
      inc position
      continue
    var start = tokenStart
    var finish = position
    while start < finish and bytes[start] == uint8(ord('"')):
      inc start
    while start < finish and bytes[finish - 1] == uint8(ord('"')):
      dec finish
    var score = 0'i64
    for index in start ..< finish:
      score += int64(bytes[index]) - 64
    if isTriangleScore(score):
      inc count
    tokenStart = position + 1
    inc position
  count

proc solution42*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "solution42".} =
  if length > MaxInputLength.csize_t:
    return -1
  if input == nil:
    return if length == 0: 0 else: -1
  if length == 0:
    return 0
  let count = int(length)
  var bytes: array[MaxInputLength, uint8]
  for index in 0 ..< count:
    let value = input[index]
    if value < 0 or value > 127:
      return -1
    bytes[index] = uint8(value)
  countFirstLine(bytes.toOpenArray(0, count - 1))
