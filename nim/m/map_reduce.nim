## Count bounded ASCII tokens in insertion order, matching the pinned Java routine.
const MaxInput = 256
const MaxWords = 128
const TableSize = 512

proc isSpaceByte(value: int64): bool {.inline.} =
  value in [9'i64, 10'i64, 11'i64, 12'i64, 13'i64, 32'i64]

proc tokenHash(input: ptr UncheckedArray[int64], start, length: int): int =
  var hash = 0
  for offset in 0 ..< length:
    hash = (hash * 31 + int(input[start + offset])) mod 1_000_003
  hash

proc tokenEqual(input: ptr UncheckedArray[int64], start, length,
                otherStart, otherLength: int): bool =
  if length != otherLength: return false
  for offset in 0 ..< length:
    if input[start + offset] != input[otherStart + offset]: return false
  true

proc writeCount(output: ptr UncheckedArray[uint8], position: var int, count: int) =
  var digits: array[3, uint8]
  var digitCount = 0
  var remaining = count
  while true:
    digits[digitCount] = uint8(ord('0') + remaining mod 10)
    inc digitCount
    remaining = remaining div 10
    if remaining == 0: break
  while digitCount > 0:
    dec digitCount
    output[position] = digits[digitCount]
    inc position

proc map_reduce*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "map_reduce".} =
  if length > csize_t(MaxInput) or (length != 0 and input == nil): return -1
  let n = int(length)
  for index in 0 ..< n:
    let value = input[index]
    if not isSpaceByte(value) and (value < 32 or value > 126): return -1

  var starts: array[MaxWords, int]
  var lengths: array[MaxWords, int]
  var counts: array[MaxWords, int]
  var table: array[TableSize, int]
  var uniqueCount = 0
  var begin = 0
  var ending = n
  while begin < ending and input[begin] <= 32: inc begin
  while ending > begin and input[ending - 1] <= 32: dec ending

  if begin == ending:
    starts[0] = 0; lengths[0] = 0; counts[0] = 1; uniqueCount = 1
    table[0] = 1
  else:
    var cursor = begin
    while cursor < ending:
      while cursor < ending and isSpaceByte(input[cursor]): inc cursor
      if cursor == ending: break
      let start = cursor
      while cursor < ending and not isSpaceByte(input[cursor]): inc cursor
      let tokenLength = cursor - start
      var slot = tokenHash(input, start, tokenLength) mod TableSize
      while table[slot] != 0:
        let item = table[slot] - 1
        if tokenEqual(input, start, tokenLength, starts[item], lengths[item]):
          inc counts[item]
          break
        slot = (slot + 1) mod TableSize
      if table[slot] == 0:
        starts[uniqueCount] = start
        lengths[uniqueCount] = tokenLength
        counts[uniqueCount] = 1
        table[slot] = uniqueCount + 1
        inc uniqueCount

  var required = 0
  for item in 0 ..< uniqueCount:
    var digits = 1
    var value = counts[item]
    while value >= 10:
      value = value div 10
      inc digits
    required += lengths[item] + 2 + digits
    if item != 0: inc required
  if output == nil or outputCapacity < csize_t(required): return -2

  var written = 0
  for item in 0 ..< uniqueCount:
    if item != 0:
      output[written] = uint8(ord(',')); inc written
    for offset in 0 ..< lengths[item]:
      output[written] = uint8(input[starts[item] + offset])
      inc written
    output[written] = uint8(ord(':')); inc written
    output[written] = uint8(ord(' ')); inc written
    writeCount(output, written, counts[item])
  int64(written)
