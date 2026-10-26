## Clean-room implementation of TSVC s293; see package rights note.
const MaxN = 32
const MaxInputLength = 33

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for b in 0 ..< 8:
    output[offset + b] = uint8(bits and 255'u64)
    bits = bits shr 8

proc tsvc_s293_first_element_broadcast*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s293_first_element_broadcast".} =
  if input.isNil or inputLength < 2 or inputLength > MaxInputLength: return -1
  if input[0] < 1 or input[0] > MaxN or inputLength != csize_t(1 + input[0]): return -1
  let n = int(input[0])
  for i in 1 ..< n + 1:
    if input[i] < -8 or input[i] > 8: return -1
  let bytes = 8*n
  if output.isNil or outputCapacity < csize_t(bytes): return -2
  var staged: array[MaxN, int64]
  for i in 0 ..< n: staged[i] = input[1]
  for i in 0 ..< n: storeI64Le(output, 8*i, staged[i])
  int64(bytes)
