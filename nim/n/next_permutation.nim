## Replace a permutation by its lexicographic successor, wrapping to minimum.
import std/algorithm
const MaxLength = 128

proc storeI32Le(output: ptr UncheckedArray[uint8], position: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[position + byte] = uint8((bits shr (byte * 8)) and 255)

proc next_permutation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "next_permutation".} =
  if input == nil or length < 1 or length > csize_t(MaxLength + 1): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var values: array[MaxLength, int32]
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
    values[i] = int32(value)
  let required = n * 4
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2
  var pivot = n
  var index = n
  while index > 1:
    dec index
    if values[index - 1] < values[index]:
      pivot = index - 1
      break
  if pivot == n:
    if n > 1: reverse(values.toOpenArray(0, n - 1))
  else:
    var successor = n - 1
    while values[successor] <= values[pivot]: dec successor
    swap(values[pivot], values[successor])
    if pivot + 1 < n: reverse(values.toOpenArray(pivot + 1, n - 1))
  for i in 0 ..< n: storeI32Le(output, i * 4, values[i])
  int64(n)
