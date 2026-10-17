const MaxInputBytes = 5000
const MaxInputValues = MaxInputBytes + 1
const ChunkWidth = 50
const MaxOutputBytes = 10

proc problem13_chunks*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "problem13_chunks".} =
  if values.isNil or length < 2 or length > MaxInputValues: return -1
  if values[0] < 1 or values[0] > MaxInputBytes or
      int(values[0]) != int(length) - 1: return -1

  let byteLength = int(values[0])
  for index in 0 ..< byteLength:
    if values[index + 1] < 48 or values[index + 1] > 57: return -1

  let width = min(byteLength, ChunkWidth)
  var reversed: array[ChunkWidth + 2, uint8]
  var reversedLength = 0
  var carry = 0
  var remaining = width
  while remaining > 0:
    dec remaining
    var column = carry
    var start = 0
    while start < byteLength:
      let chunkLength = min(ChunkWidth, byteLength - start)
      if remaining < chunkLength:
        column += int(values[1 + start + remaining] - 48)
      start += ChunkWidth
    reversed[reversedLength] = uint8(column mod 10)
    inc reversedLength
    carry = column div 10
  while carry > 0:
    reversed[reversedLength] = uint8(carry mod 10)
    inc reversedLength
    carry = carry div 10

  let outputLength = min(reversedLength, MaxOutputBytes)
  if output.isNil or int(capacity) < outputLength: return -2
  for index in 0 ..< outputLength:
    output[index] = uint8(48 + int(reversed[reversedLength - 1 - index]))
  int64(outputLength)
