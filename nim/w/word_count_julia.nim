## Count Julia-regex words after ASCII lowercasing.
const MaxLength = 1000

type WordEntry = object
  start, length, count: int

proc lowerByte(input: ptr UncheckedArray[int64], index: int): uint8 =
  let byte = uint8(input[index])
  if byte >= ord('A').uint8 and byte <= ord('Z').uint8: byte + (ord('a') - ord('A')).uint8 else: byte

proc isWordByte(byte: uint8): bool =
  (byte >= ord('a').uint8 and byte <= ord('z').uint8) or
    (byte >= ord('0').uint8 and byte <= ord('9').uint8) or byte == ord('_').uint8

proc compareWord(input: ptr UncheckedArray[int64], start, length: int, entry: WordEntry): int =
  let shared = min(length, entry.length)
  for offset in 0 ..< shared:
    let left = lowerByte(input, start + offset)
    let right = lowerByte(input, entry.start + offset)
    if left < right: return -1
    if left > right: return 1
  if length < entry.length: -1 elif length > entry.length: 1 else: 0

proc writeCount(output: ptr UncheckedArray[uint8], position: var int, count: int) =
  var digits: array[4, uint8]
  var digitCount = 0
  var remaining = count
  while true:
    digits[digitCount] = uint8(ord('0') + remaining mod 10)
    inc digitCount
    remaining = remaining div 10
    if remaining == 0: break
  output[position] = uint8(ord('=')); inc position
  while digitCount > 0:
    dec digitCount
    output[position] = digits[digitCount]; inc position
  output[position] = uint8(ord('\n')); inc position

proc word_count_julia*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "word_count_julia".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  let count = int(length)
  for index in 0 ..< count:
    if input[index] < 0 or input[index] > 127: return -1
  var entries: array[MaxLength, WordEntry]
  var uniqueCount = 0
  var index = 0
  while index < count:
    if not isWordByte(lowerByte(input, index)):
      inc index
      continue
    let start = index
    while index < count and isWordByte(lowerByte(input, index)): inc index
    var tokenLength = index - start
    if index + 1 < count and input[index] == ord('\'').int64 and isWordByte(lowerByte(input, index + 1)):
      tokenLength += 2
      index += 2
    var position = 0
    while position < uniqueCount and compareWord(input, start, tokenLength, entries[position]) > 0: inc position
    if position < uniqueCount and compareWord(input, start, tokenLength, entries[position]) == 0:
      inc entries[position].count
    else:
      var move = uniqueCount
      while move > position:
        entries[move] = entries[move - 1]
        dec move
      entries[position] = WordEntry(start: start, length: tokenLength, count: 1)
      inc uniqueCount

  var required = 0
  for item in 0 ..< uniqueCount:
    var digits = 1
    var value = entries[item].count
    while value >= 10:
      value = value div 10
      inc digits
    required += entries[item].length + digits + 2
  if outputCapacity < csize_t(required) or (required != 0 and output == nil): return -2
  var written = 0
  for item in 0 ..< uniqueCount:
    for offset in 0 ..< entries[item].length:
      output[written] = lowerByte(input, entries[item].start + offset)
      inc written
    writeCount(output, written, entries[item].count)
  int64(written)
