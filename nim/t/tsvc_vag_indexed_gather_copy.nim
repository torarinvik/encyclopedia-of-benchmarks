const MaxN = 64
const MaxInputLength = 1 + 2 * MaxN
const MaxValue = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_vag_indexed_gather_copy*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_vag_indexed_gather_copy".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + 2 * n: return -1
  for i in 0 ..< n:
    let index = input[1 + i]
    let value = input[1 + n + i]
    if index < 0 or index >= int64(n): return -1
    if value < -MaxValue or value > MaxValue: return -1
  if output == nil or outputCapacity < csize_t(8 * n): return -2

  for i in 0 ..< n:
    let index = int(input[1 + i])
    storeI64Le(output, 8 * i, input[1 + n + index])
  int64(n)
