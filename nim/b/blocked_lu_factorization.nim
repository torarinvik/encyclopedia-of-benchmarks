import std/math

const MaxN = 8
const MaxInputLength = 66
const MaxOutputElements = 128

proc exactInteger(x: float64, lo, hi: int64): bool =
  if classify(x) in {fcNan, fcInf, fcNegInf}: return false
  if x < float64(lo) or x > float64(hi): return false
  float64(int64(x)) == x

proc finiteValue(x: float64): bool =
  classify(x) notin {fcNan, fcInf, fcNegInf}

proc blocked_lu_factorization*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "blocked_lu_factorization".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 2, MaxN.int64): return -1
  let n = int(input[0])
  if n mod 2 != 0 or inputLength != csize_t(1 + n * n): return -1
  var schur: array[64, float64]
  for row in 0 ..< n:
    var offSum = 0'i64
    for col in 0 ..< n:
      let x = input[1 + row * n + col]
      let lo = if row == col: 1'i64 else: -2'i64
      let hi = if row == col: 16'i64 else: 2'i64
      if not exactInteger(x, lo, hi): return -1
      let value = int64(x)
      schur[row * n + col] = float64(value)
      if row != col: offSum += abs(value)
    if int64(schur[row * n + row]) <= offSum: return -1

  var lower, upper: array[64, float64]
  for k in countup(0, n - 2, 2):
    let u00 = schur[k * n + k]
    let u01 = schur[k * n + k + 1]
    if not finiteValue(u00) or u00 == 0.0: return -1
    let l10 = schur[(k + 1) * n + k] / u00
    let u11 = schur[(k + 1) * n + k + 1] - l10 * u01
    if not finiteValue(l10) or not finiteValue(u11) or u11 == 0.0: return -1
    lower[k * n + k] = 1.0
    lower[(k + 1) * n + k] = l10
    lower[(k + 1) * n + k + 1] = 1.0
    upper[k * n + k] = u00
    upper[k * n + k + 1] = u01
    upper[(k + 1) * n + k + 1] = u11
    var j = k + 2
    while j < n:
      for col in j ..< j + 2:
        let s0 = schur[k * n + col]
        let s1 = schur[(k + 1) * n + col]
        upper[k * n + col] = s0
        upper[(k + 1) * n + col] = s1 - l10 * s0
      j += 2
    var i = k + 2
    while i < n:
      for row in i ..< i + 2:
        let s0 = schur[row * n + k]
        let s1 = schur[row * n + k + 1]
        let l0 = s0 / u00
        let l1 = (s1 - l0 * u01) / u11
        lower[row * n + k] = l0
        lower[row * n + k + 1] = l1
      i += 2
    i = k + 2
    while i < n:
      j = k + 2
      while j < n:
        for row in i ..< i + 2:
          for col in j ..< j + 2:
            let update = lower[row * n + k] * upper[k * n + col] + lower[row * n + k + 1] * upper[(k + 1) * n + col]
            schur[row * n + col] -= update
        j += 2
      i += 2

  let m = n * n
  var staged: array[MaxOutputElements, float64]
  for row in 0 ..< n:
    lower[row * n + row] = 1.0
    for col in row ..< n: upper[row * n + col] = schur[row * n + col]
  for i in 0 ..< m:
    if not finiteValue(lower[i]) or not finiteValue(upper[i]): return -1
    staged[i] = lower[i]
    staged[m + i] = upper[i]
  let outputLength = 2 * m
  if output == nil or outputCapacity < csize_t(outputLength): return -2
  for i in 0 ..< outputLength: output[i] = staged[i]
  int64(outputLength)
