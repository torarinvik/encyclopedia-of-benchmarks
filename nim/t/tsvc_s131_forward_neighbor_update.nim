const MaxN = 64
const MaxInputLength = 2 + 2 * MaxN
const MaxValue = 1_000_000'i64
const MaxPasses = 32

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc boundedValue(value: int64): bool =
  value >= -MaxValue and value <= MaxValue

proc tsvc_s131_forward_neighbor_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s131_forward_neighbor_update".} =
  if input == nil or length < 4 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let passes = input[1]
  if nValue < 1 or nValue > MaxN or passes < 1 or passes > MaxPasses: return -1
  let n = int(nValue)
  if int(length) != 2 + 2 * n: return -1

  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[2 + i]
    b[i] = input[2 + n + i]
    if not boundedValue(a[i]) or not boundedValue(b[i]): return -1
  if output == nil or outputCapacity < csize_t(8 * n): return -2

  for pass in 0 ..< int(passes):
    for i in 0 ..< n - 1:
      a[i] = a[i + 1] + b[i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
  int64(n)
