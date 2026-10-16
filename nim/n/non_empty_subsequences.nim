const MaxRunes = 8
const MaxInputLength = MaxRunes + 2
const BytesPerValue = 4

proc isUnicodeScalar(value: int64): bool =
  value >= 0 and value <= 0x10ffff and not (value >= 0xd800 and value <= 0xdfff)

proc storeU32Le(output: ptr UncheckedArray[uint8], position: int, value: uint32) =
  for byte in 0 ..< BytesPerValue:
    output[position + byte] = uint8((value shr (byte * 8)) and 255)

proc emitRow(current: array[MaxRunes, int32], length: int,
    output: ptr UncheckedArray[uint8], outputCursor: var int, rowCount: var int) =
  storeU32Le(output, outputCursor, uint32(length))
  outputCursor += BytesPerValue
  for item in 0 ..< length:
    storeU32Le(output, outputCursor, cast[uint32](current[item]))
    outputCursor += BytesPerValue
  inc rowCount

proc generate(values: array[MaxRunes, int32], n, start: int,
    current: var array[MaxRunes, int32], currentLength: int,
    output: ptr UncheckedArray[uint8], outputCursor: var int, rowCount: var int) =
  for index in start ..< n:
    current[currentLength] = values[index]
    emitRow(current, currentLength + 1, output, outputCursor, rowCount)
    generate(values, n, index + 1, current, currentLength + 1, output, outputCursor, rowCount)

proc non_empty_subsequences*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "non_empty_subsequences".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let countValue = input[0]
  if countValue < 1 or countValue > MaxRunes or length != csize_t(countValue + 1): return -1
  let n = int(countValue)
  var values: array[MaxRunes, int32]
  for index in 0 ..< n:
    let value = input[index + 1]
    if not isUnicodeScalar(value): return -1
    values[index] = int32(value)

  let rows = (1 shl n) - 1
  let valueCount = n * (1 shl (n - 1))
  let required = (rows + valueCount) * BytesPerValue
  if outputCapacity < csize_t(required) or output == nil: return -2

  var current: array[MaxRunes, int32]
  var outputCursor = 0
  var emitted = 0
  generate(values, n, 0, current, 0, output, outputCursor, emitted)
  int64(emitted)
