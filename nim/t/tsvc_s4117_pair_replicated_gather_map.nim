## Clean-room bounded port of TSVC s4117; see package README for provenance.
const MaxN = 64
const MaxInputLength = 161

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s4117_pair_replicated_gather_map*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s4117_pair_replicated_gather_map".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  let cLength = (n + 1) div 2
  if length != csize_t(1 + 2 * n + cLength): return -1
  for i in 1 ..< int(length):
    if input[i] < -2 or input[i] > 2: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  let bOffset = 1
  let cOffset = 1 + n
  let dOffset = cOffset + cLength
  for i in 0 ..< n:
    let value = input[bOffset + i] + input[cOffset + i div 2] * input[dOffset + i]
    storeI64Le(output, 8 * i, value)
  int64(n)
