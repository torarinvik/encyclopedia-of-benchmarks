## Clean-room port of TSVC s258; see package README for provenance and rights.
const MaxN = 64
const MaxInputLength = 257

proc tsvc_s258_wrapped_scalar_expansion*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s258_wrapped_scalar_expansion".} =
  if input.isNil or length < 5 or length > csize_t(MaxInputLength): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(1 + 4 * n): return -1
  var a, c, d, aa0, b, e: array[MaxN, int64]
  let cStart = 1 + n
  let dStart = 1 + 2 * n
  let aaStart = 1 + 3 * n
  for i in 0 ..< n:
    a[i] = input[1 + i]
    c[i] = input[cStart + i]
    d[i] = input[dStart + i]
    aa0[i] = input[aaStart + i]
    if a[i] < 0 or a[i] > 2 or c[i] < 0 or c[i] > 2 or
        d[i] < 0 or d[i] > 2 or aa0[i] < 0 or aa0[i] > 2: return -1
  var s = 0'i64
  for i in 0 ..< n:
    if a[i] > 0: s = d[i] * d[i]
    b[i] = s * c[i] + d[i]
    e[i] = (s + 1) * aa0[i]
  var sumB, sumE = 0'i64
  for i in 0 ..< n:
    sumB += b[i]
    sumE += e[i]
  sumB + sumE
