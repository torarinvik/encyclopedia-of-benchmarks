const MaxN = 64
const MaxInputLength = 1 + MaxN
const MaxValue = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s315_maximum_with_index*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s315_maximum_with_index".} =
  if input == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + n: return -1
  for i in 0 ..< n:
    if input[i + 1] < -MaxValue or input[i + 1] > MaxValue: return -1
  if output == nil or outputCapacity < 16: return -2

  var maximum = input[1]
  var maximumIndex = 0
  for i in 0 ..< n:
    let value = input[i + 1]
    if value > maximum:
      maximum = value
      maximumIndex = i
  storeI64Le(output, 0, maximum)
  storeI64Le(output, 8, int64(maximumIndex))
  2
