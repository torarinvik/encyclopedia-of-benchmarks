import std/math

const InvalidResult = -1.0e300
const Delta = 1.0e-9

proc correlation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "correlation".} =
  if values == nil or length < 3: return InvalidResult
  let nValue = values[0]
  if nValue < 1 or nValue > 128 or length != 1 + 2 * csize_t(nValue): return InvalidResult
  let n = int(nValue)
  var exy = 0.0
  var ex = 0.0
  var exx = 0.0
  var ey = 0.0
  var eyy = 0.0
  for i in 0 ..< n:
    let xi = values[1 + i]
    let yi = values[1 + n + i]
    if xi < -1000 or xi > 1000 or yi < -1000 or yi > 1000: return InvalidResult
    let x = float64(xi)
    let y = float64(yi)
    exy += x * y
    ex += x
    exx += x * x
    ey += y
    eyy += y * y
  exy /= float64(n)
  ex /= float64(n)
  exx /= float64(n)
  ey /= float64(n)
  eyy /= float64(n)
  let cov = exy - ex * ey
  let varx = sqrt(exx - ex * ex)
  let vary = sqrt(eyy - ey * ey)
  if varx * vary < Delta: return 0.0
  cov / sqrt(varx * vary)
