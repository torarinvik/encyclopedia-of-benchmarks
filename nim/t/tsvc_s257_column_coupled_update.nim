const MaxN = 8
const MaxPasses = 4

proc tsvc_s257_column_coupled_update*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s257_column_coupled_update".} =
  if values.isNil or length < csize_t(12) or length > csize_t(2 + MaxN + 2 * MaxN * MaxN): return -1
  let nValue = values[0]
  let passesValue = values[1]
  if nValue < 2 or nValue > MaxN or passesValue < 1 or passesValue > MaxPasses: return -1
  let n = int(nValue)
  let passes = int(passesValue)
  if length != csize_t(2 + n + 2 * n * n): return -1
  for index in 2 ..< int(length):
    if values[index] < -1 or values[index] > 1: return -1

  var a: array[MaxN, int64]
  var aa, bb: array[MaxN * MaxN, int64]
  for i in 0 ..< n: a[i] = values[2 + i]
  let aaStart = 2 + n
  let bbStart = aaStart + n * n
  for i in 0 ..< n * n:
    aa[i] = values[aaStart + i]
    bb[i] = values[bbStart + i]
  for pass in 0 ..< passes:
    discard pass
    for i in 1 ..< n:
      for j in 0 ..< n:
        let cell = j * n + i
        a[i] = aa[cell] - a[i - 1]
        aa[cell] = a[i] + bb[cell]

  var checksum = 0'i64
  for i in 0 ..< n: checksum += a[i]
  for i in 0 ..< n * n: checksum += aa[i]
  checksum
