## Clean-room bounded port of TSVC s253; see package README for provenance.
const MaxN = 64
const MaxPasses = 8
const MaxInputLength = 2 + 4 * MaxN

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u64)

proc tsvc_s253_conditional_affine_update*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tsvc_s253_conditional_affine_update".} =
  if input.isNil or length < 6 or length > csize_t(MaxInputLength): return -1
  let nRaw = input[0]
  let passesRaw = input[1]
  if nRaw < 1 or nRaw > MaxN or passesRaw < 1 or passesRaw > MaxPasses: return -1
  let n = int(nRaw)
  let passes = int(passesRaw)
  if length != csize_t(2 + 4 * n): return -1
  for i in 2 ..< int(length):
    if input[i] < -2 or input[i] > 2: return -1
  if output.isNil or outputCapacity < csize_t(16 * n): return -2

  let aStart = 2
  let bStart = aStart + n
  let cStart = bStart + n
  let dStart = cStart + n
  var a, c: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = input[aStart + i]
    c[i] = input[cStart + i]
  for _ in 0 ..< passes:
    for i in 0 ..< n:
      let bValue = input[bStart + i]
      if a[i] > bValue:
        let value = a[i] - bValue * input[dStart + i]
        c[i] += value
        a[i] = value
  for i in 0 ..< n:
    storeI64Le(output, 8 * i, a[i])
    storeI64Le(output, 8 * (n + i), c[i])
  int64(2 * n)
