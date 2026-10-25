## Clean-room bounded port of TSVC s332; see package README for provenance.
const MaxN = 256
const MaxInputLength = 258

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s332_first_above_threshold*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s332_first_above_threshold".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < -1000000 or input[1] > 1000000: return -1
  let n = int(input[0])
  let threshold = input[1]
  if length != csize_t(2 + n): return -1
  var values: array[MaxN, int64]
  for i in 0 ..< n:
    values[i] = input[2 + i]
    if values[i] < -1000000 or values[i] > 1000000: return -1
  if output.isNil or capacity < 16: return -2
  var index = -2'i64
  var value = -1'i64
  for i in 0 ..< n:
    if values[i] > threshold:
      index = int64(i)
      value = values[i]
      break
  storeI64Le(output, 0, index)
  storeI64Le(output, 8, value)
  2
