const MaxN = 64
const MaxInputLength = 2 + 5 * MaxN
const MaxValue = 2'i64
const MaxPasses = 16'i64

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc boundedValue(value: int64): bool =
  value >= -MaxValue and value <= MaxValue

proc tsvc_s278_branch_recompute*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s278_branch_recompute".} =
  if input == nil or length < 7 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let passes = input[1]
  if nValue < 1 or nValue > MaxN or passes < 1 or passes > MaxPasses: return -1
  let n = int(nValue)
  if int(length) != 2 + 5 * n: return -1

  let aStart = 2
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  let eStart = dStart + n
  var a, b, c: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    b[i] = input[bStart + i]
    c[i] = input[cStart + i]
    if not boundedValue(a[i]) or not boundedValue(b[i]) or not boundedValue(c[i]) or
        not boundedValue(input[dStart + i]) or not boundedValue(input[eStart + i]): return -1
  if output == nil or outputCapacity < csize_t(24 * n): return -2

  for _pass in 0 ..< int(passes):
    for i in 0 ..< n:
      let de = input[dStart + i] * input[eStart + i]
      if a[i] > 0:
        c[i] = -c[i] + de
      else:
        b[i] = -b[i] + de
      a[i] = b[i] + c[i] * input[dStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
    storeI64Le(output, 8 * (2 * n + i), c[i])
  int64(3 * n)
