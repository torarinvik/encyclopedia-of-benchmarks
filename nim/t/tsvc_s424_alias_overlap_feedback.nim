## Clean-room port of TSVC s424; see package README for provenance and rights.
const MinN = 66
const MaxN = 192
const XLength = MaxN + 63
const MaxInputLength = MaxN + 64

proc tsvc_s424_alias_overlap_feedback*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s424_alias_overlap_feedback".} =
  if input.isNil or length < csize_t(MinN + 64) or length > csize_t(MaxInputLength): return -1
  if input[0] < MinN or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(n + 64): return -1
  var a: array[MaxN, int64]
  var x: array[XLength, int64]
  for i in 0 ..< n:
    a[i] = input[1 + i]
    if a[i] < 0 or a[i] > 10: return -1
  for i in 0 ..< 63:
    x[i] = input[1 + n + i]
    if x[i] < 0 or x[i] > 10: return -1
  for i in 63 ..< XLength:
    x[i] = 0
  for i in 0 ..< n - 1:
    x[i + 64] = x[i] + a[i]
  var checksum = 0'i64
  for i in 0 ..< n:
    checksum += x[63 + i]
  checksum
