## Emit permutations in depth-first input-index order; equal values keep multiplicity.
const MaxLength = 6
const BytesPerValue = 4

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255)

proc generate(values: array[MaxLength, int32], n, depth: int,
    current: var array[MaxLength, int32], used: var array[MaxLength, bool],
    output: ptr UncheckedArray[uint8], resultCount: var int) =
  if depth == n:
    let rowStart = resultCount * n * BytesPerValue
    for index in 0 ..< n:
      storeI32Le(output, rowStart + index * BytesPerValue, current[index])
    inc resultCount
    return
  for index in 0 ..< n:
    if used[index]: continue
    current[depth] = values[index]
    used[index] = true
    generate(values, n, depth + 1, current, used, output, resultCount)
    used[index] = false

proc all_permutations*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "all_permutations".} =
  if input == nil or length < 1 or length > csize_t(MaxLength + 1): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var values: array[MaxLength, int32]
  for index in 0 ..< n:
    let value = input[index + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[index] = int32(value)
  var permutationCount = 1
  for factor in 2 .. n: permutationCount *= factor
  let required = permutationCount * n * BytesPerValue
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2
  var current: array[MaxLength, int32]
  var used: array[MaxLength, bool]
  var resultCount = 0
  generate(values, n, 0, current, used, output, resultCount)
  int64(resultCount)
