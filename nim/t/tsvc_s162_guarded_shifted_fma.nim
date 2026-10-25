## Clean-room bounded port of TSVC s162; see package README for provenance.
const MaxN = 64
const MaxInputLength = 194

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s162_guarded_shifted_fma*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s162_guarded_shifted_fma".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 0 or input[1] > 1: return -1
  let n = int(input[0])
  if length != csize_t(2 + 3 * n): return -1
  for i in 2 ..< int(length):
    if input[i] < -2 or input[i] > 2: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  let aOffset = 2
  let bOffset = aOffset + n
  let cOffset = bOffset + n
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, input[aOffset + i])
  if input[1] > 0:
    for i in 0 ..< n - 1:
      let value = input[aOffset + i + 1] + input[bOffset + i] * input[cOffset + i]
      storeI64Le(output, 8 * i, value)
  int64(n)
