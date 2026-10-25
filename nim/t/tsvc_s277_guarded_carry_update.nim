# Clean-room bounded port of TSVC s277; see package README for provenance.
const MaxN = 64
const MaxPasses = 8
const MaxInputLength = 2 + 5 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s277_guarded_carry_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s277_guarded_carry_update".} =
  if input.isNil or length < 7 or length > csize_t(MaxInputLength): return -1
  let nRaw = input[0]
  let passesRaw = input[1]
  if nRaw < 1 or nRaw > MaxN or passesRaw < 1 or passesRaw > MaxPasses: return -1
  let n = int(nRaw)
  let passes = int(passesRaw)
  if length != csize_t(2 + 5 * n): return -1
  for i in 2 ..< int(length):
    if input[i] < -2 or input[i] > 2: return -1
  if output.isNil or outputCapacity < csize_t(16 * n): return -2

  let aStart = 2
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  let eStart = dStart + n
  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    b[i] = input[bStart + i]
  for _ in 0 ..< passes:
    for i in 0 ..< n - 1:
      if a[i] >= 0: continue
      if b[i] < 0: a[i] += input[cStart + i] * input[dStart + i]
      b[i + 1] = input[cStart + i] + input[dStart + i] * input[eStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
  int64(2 * n)
