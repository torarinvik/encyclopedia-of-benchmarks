const MaxValues = 32
const MaxHighBits = 96
const MaxParseableInputLength = 35

proc elias_fano_monotone_sequence*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "elias_fano_monotone_sequence".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxParseableInputLength): return -1
  let countValue = input[0]
  let upperBound = input[1]
  if countValue < 1'i64 or countValue > int64(MaxValues) or
      upperBound < 0'i64 or upperBound > 1_000_000'i64 or
      countValue > upperBound + 1'i64:
    return -1
  let count = int(countValue)
  if length != csize_t(count + 2): return -1

  var values: array[MaxValues, int64]
  var previous = -1'i64
  for i in 0..<count:
    let value = input[i + 2]
    if value < 0'i64 or value > upperBound or value < previous: return -1
    values[i] = value
    previous = value

  var lowWidth = 0
  while int64(count) * (1'i64 shl (lowWidth + 1)) <= upperBound + 1'i64:
    inc lowWidth
  let width = 1'i64 shl lowWidth
  let lowMask = width - 1
  let highLength = int(upperBound div width) + count
  if highLength < count or highLength > MaxHighBits: return -1

  var lowParts: array[MaxValues, int64]
  var highBits: array[MaxHighBits, bool]
  for i in 0..<count:
    lowParts[i] = values[i] and lowMask
    let position = int(values[i] div width) + i
    if position < 0 or position >= highLength: return -1
    highBits[position] = true

  var checksum = 0'i64
  var itemIndex = 0
  for position in 0..<highLength:
    if highBits[position]:
      if itemIndex >= count or position < itemIndex: return -1
      let highPart = int64(position - itemIndex)
      let decoded = highPart * width + lowParts[itemIndex]
      checksum += int64(itemIndex + 1) * decoded
      inc itemIndex
  if itemIndex != count: return -1
  checksum
