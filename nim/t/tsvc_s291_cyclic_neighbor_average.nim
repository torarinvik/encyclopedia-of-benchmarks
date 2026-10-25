const MaxN = 64
const MaxInputLength = 1 + MaxN
const MaxValue = 1_000_000'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc tsvc_s291_cyclic_neighbor_average*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s291_cyclic_neighbor_average".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  if nValue < 2 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != 1 + n: return -1
  for i in 0 ..< n:
    if input[i + 1] < -MaxValue or input[i + 1] > MaxValue: return -1
  if output == nil or outputCapacity < csize_t(8 * n): return -2

  for i in 0 ..< n:
    let previous = if i == 0: n - 1 else: i - 1
    storeI64Le(output, 8 * i, input[i + 1] + input[previous + 1])
  int64(n)
