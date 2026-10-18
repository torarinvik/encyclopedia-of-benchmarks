## Emit Java-style swap-recursion permutations, retaining duplicate rows.
const MaxLength = 6
const MaxParseableLength = 8

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[position + byte] = uint8((bits shr (byte * 8)) and 255)

proc generate(values: var array[MaxLength, int32], n, index: int,
    output: ptr UncheckedArray[uint8], resultCount: var int) =
  if index == n:
    let rowStart = resultCount * n * 4
    for column in 0 ..< n:
      storeI32Le(output, rowStart + column * 4, values[column])
    inc resultCount
    return
  for position in index ..< n:
    let saved = values[index]
    values[index] = values[position]
    values[position] = saved
    generate(values, n, index + 1, output, resultCount)
    let restore = values[index]
    values[index] = values[position]
    values[position] = restore

proc permutation_array*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "permutation_array".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
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
  let required = permutationCount * n * 4
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2
  var resultCount = 0
  generate(values, n, 0, output, resultCount)
  int64(resultCount)
