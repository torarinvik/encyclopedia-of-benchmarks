const MaxN = 64
const MaxPasses = 8

proc tsvc_s273_dependent_conditional_update*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s273_dependent_conditional_update".} =
  if values.isNil or length < csize_t(7) or length > csize_t(2 + 5 * MaxN): return -1
  let nValue = values[0]
  let passesValue = values[1]
  if nValue < 1 or nValue > MaxN or passesValue < 1 or passesValue > MaxPasses: return -1
  let n = int(nValue)
  let passes = int(passesValue)
  if length != csize_t(2 + 5 * n): return -1
  for index in 2 ..< int(length):
    if values[index] < -2 or values[index] > 2: return -1

  var a, b, c, d, e: array[MaxN, int64]
  for i in 0 ..< n:
    a[i] = values[2 + i]
    b[i] = values[2 + n + i]
    c[i] = values[2 + 2 * n + i]
    d[i] = values[2 + 3 * n + i]
    e[i] = values[2 + 4 * n + i]
  for iteration in 0 ..< passes:
    discard iteration
    for i in 0 ..< n:
      a[i] += d[i] * e[i]
      if a[i] < 0: b[i] += d[i] * e[i]
      c[i] += a[i] * d[i]
  var checksum = 0'i64
  for i in 0 ..< n: checksum += a[i] + b[i] + c[i]
  checksum
