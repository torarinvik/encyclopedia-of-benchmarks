# Clean-room bounded port of TSVC s272; see package README for provenance.
const MaxN = 64
const MaxPasses = 8
const MaxInputLength = 3 + 5 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s272_threshold_dual_accumulate*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s272_threshold_dual_accumulate".} =
  if input.isNil or length < 8 or length > csize_t(MaxInputLength): return -1
  let nRaw = input[0]
  let passesRaw = input[1]
  let threshold = input[2]
  if nRaw < 1 or nRaw > MaxN or passesRaw < 1 or passesRaw > MaxPasses or threshold < -2 or threshold > 2: return -1
  let n = int(nRaw)
  let passes = int(passesRaw)
  if length != csize_t(3 + 5 * n): return -1
  for i in 3 ..< int(length):
    if input[i] < -2 or input[i] > 2: return -1
  if output.isNil or outputCapacity < csize_t(16 * n): return -2

  let aStart = 3
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  let eStart = dStart + n
  var a, b: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    b[i] = input[bStart + i]
  for _ in 0 ..< passes:
    for i in 0 ..< n:
      if input[eStart + i] >= threshold:
        a[i] += input[cStart + i] * input[dStart + i]
        b[i] += input[cStart + i] * input[cStart + i]
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), b[i])
  int64(2 * n)
