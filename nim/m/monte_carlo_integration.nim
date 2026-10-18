const MaxN = 16
const MinBound = -10_000_000'i64
const MaxBound = 10_000_000'i64
const MaxUniform = 999_999'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc monte_carlo_integration*(packed: I64Input, length: csize_t): float64 {.cdecl, exportc: "monte_carlo_integration".} =
  if packed == nil or length < 3 or length > 12: return InvalidResult
  let n = packed[2]
  if n < 1 or n > MaxN or length != csize_t(3 + (n + 1) div 2): return InvalidResult
  let aRaw = packed[0]
  let bRaw = packed[1]
  if aRaw < MinBound or aRaw > MaxBound or bRaw < MinBound or bRaw > MaxBound or aRaw >= bRaw: return InvalidResult
  for index in 3 ..< int(length):
    if packed[index] < 0 or packed[index] > MaxUniform: return InvalidResult

  let a = float64(aRaw) / 1_000_000.0
  let b = float64(bRaw) / 1_000_000.0
  let interval = b - a
  var total = 0.0
  for index in 0 ..< int(n div 2):
    let u = float64(packed[3 + index]) / 1_000_000.0
    let x1 = a + u * interval
    let x2 = a + (1.0 - u) * interval
    total += x1 * x1
    total += x2 * x2
  if n mod 2 == 1:
    let u = float64(packed[3 + int(n div 2)]) / 1_000_000.0
    let x = a + u * interval
    total += x * x
  interval * total / float64(n)
