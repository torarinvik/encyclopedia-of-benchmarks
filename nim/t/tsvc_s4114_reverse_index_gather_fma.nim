## Clean-room bounded port of TSVC s4114; see package README for provenance.
const MaxN = 64
const MaxInputLength = 257

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s4114_reverse_index_gather_fma*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s4114_reverse_index_gather_fma".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 4 * n): return -1
  let ipOffset = 1
  let bOffset = 1 + n
  let cOffset = 1 + 2 * n
  let dOffset = 1 + 3 * n
  for i in 0 ..< n:
    if input[ipOffset + i] < 0 or input[ipOffset + i] >= int64(n): return -1
    if input[bOffset + i] < -2 or input[bOffset + i] > 2 or
        input[cOffset + i] < -2 or input[cOffset + i] > 2 or
        input[dOffset + i] < -2 or input[dOffset + i] > 2: return -1
  if output.isNil or capacity < csize_t(8 * n): return -2
  for i in 0 ..< n:
    let gathered = n - 1 - int(input[ipOffset + i])
    let value = input[bOffset + i] + input[cOffset + gathered] * input[dOffset + i]
    storeI64Le(output, 8 * i, value)
  int64(n)
