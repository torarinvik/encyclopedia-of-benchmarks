## Clean-room bounded port of TSVC s171; see package README for provenance.
const MaxN = 32
const MaxStride = 4
const MaxInputLength = 159

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s171_stride_indexed_accumulate*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s171_stride_indexed_accumulate".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN or input[1] < 1 or input[1] > MaxStride: return -1
  let n = int(input[0])
  let stride = int(input[1])
  let aLength = 1 + (n - 1) * stride
  if length != csize_t(2 + aLength + n): return -1
  for i in 0 ..< aLength + n:
    if input[2 + i] < -8 or input[2 + i] > 8: return -1
  if output.isNil or capacity < csize_t(8 * aLength): return -2
  for i in 0 ..< aLength:
    storeI64Le(output, 8 * i, input[2 + i])
  let bOffset = 2 + aLength
  for i in 0 ..< n:
    let destination = i * stride
    storeI64Le(output, 8 * destination, input[2 + destination] + input[bOffset + i])
  int64(aLength)
