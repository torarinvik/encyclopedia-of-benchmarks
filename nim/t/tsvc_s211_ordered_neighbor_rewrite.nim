const MaxN = 64
const MaxInputLength = 2 + 5 * MaxN
const MaxValue = 2'i64
const MaxPasses = 32

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc boundedValue(value: int64): bool =
  value >= -MaxValue and value <= MaxValue

proc tsvc_s211_ordered_neighbor_rewrite*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s211_ordered_neighbor_rewrite".} =
  if input == nil or length < 17 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let passes = input[1]
  if nValue < 3 or nValue > MaxN or passes < 1 or passes > MaxPasses: return -1
  let n = int(nValue)
  if int(length) != 2 + 5 * n: return -1

  let aStart = 2
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  let eStart = dStart + n
  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    b[i] = input[bStart + i]
    if not boundedValue(a[i]) or not boundedValue(b[i]) or
        not boundedValue(input[cStart + i]) or not boundedValue(input[dStart + i]) or
        not boundedValue(input[eStart + i]): return -1
  if output == nil or outputCapacity < csize_t(16 * n): return -2

  for _pass in 0 ..< int(passes):
    for i in 1 ..< n - 1:
      a[i] = b[i - 1] + input[cStart + i] * input[dStart + i]
      b[i] = b[i + 1] - input[eStart + i] * input[dStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
  int64(2 * n)
