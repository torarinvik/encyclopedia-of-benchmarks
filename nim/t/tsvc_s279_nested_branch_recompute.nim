# Clean-room bounded port of TSVC s279; see package README for provenance.
const MaxN = 64
const MaxPasses = 8
const MaxInputLength = 2 + 5 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s279_nested_branch_recompute*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s279_nested_branch_recompute".} =
  if input.isNil or length < 7 or length > csize_t(MaxInputLength): return -1
  let nRaw = input[0]
  let passesRaw = input[1]
  if nRaw < 1 or nRaw > MaxN or passesRaw < 1 or passesRaw > MaxPasses: return -1
  let n = int(nRaw)
  let passes = int(passesRaw)
  if length != csize_t(2 + 5 * n): return -1
  for i in 2 ..< int(length):
    if input[i] < -2 or input[i] > 2: return -1
  if output.isNil or outputCapacity < csize_t(24 * n): return -2

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
  for _ in 0 ..< passes:
    for i in 0 ..< n:
      if a[i] > 0:
        c[i] = -c[i] + input[eStart + i] * input[eStart + i]
      else:
        b[i] = -b[i] + input[dStart + i] * input[dStart + i]
        if b[i] > a[i]: c[i] += input[dStart + i] * input[eStart + i]
      a[i] = b[i] + c[i] * input[dStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
    storeI64Le(output, 8 * (2 * n + i), c[i])
  int64(3 * n)
