## Emit subsequences in skip-before-include depth-first order.
const MaxLength = 8
const BytesPerValue = 4

proc storeU32Le(output: ptr UncheckedArray[uint8], position: int, value: uint32) =
  for byte in 0 ..< 4:
    output[position + byte] = uint8((value shr (byte * 8)) and 255)

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int32) =
  storeU32Le(output, position, cast[uint32](value))

proc generate(values: array[MaxLength, int32], n, index: int,
    current: var array[MaxLength, int32], currentLength: int,
    output: ptr UncheckedArray[uint8], outputCursor: var int, resultCount: var int) =
  if index == n:
    storeU32Le(output, outputCursor, uint32(currentLength))
    outputCursor += BytesPerValue
    for item in 0 ..< currentLength:
      storeI32Le(output, outputCursor, current[item])
      outputCursor += BytesPerValue
    inc resultCount
    return
  generate(values, n, index + 1, current, currentLength, output, outputCursor, resultCount)
  current[currentLength] = values[index]
  generate(values, n, index + 1, current, currentLength + 1, output, outputCursor, resultCount)

proc all_subsequences*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "all_subsequences".} =
  if input == nil or length < 1 or length > csize_t(MaxLength + 1): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var values: array[MaxLength, int32]
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = int32(value)
  var resultCount = 1
  for index in 0 ..< n: resultCount *= 2
  let valueCount = if n == 0: 0 else: n * (resultCount div 2)
  let required = (resultCount + valueCount) * BytesPerValue
  if outputCapacity < csize_t(required) or output == nil: return -2
  var current: array[MaxLength, int32]
  var outputCursor = 0
  var emitted = 0
  generate(values, n, 0, current, 0, output, outputCursor, emitted)
  int64(emitted)
