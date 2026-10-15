## Net present value with source-ordered binary64 terms.
import std/math
proc npv*(input: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "npv".} =
  const invalid = -1e300
  if input.isNil or length < 2: return invalid
  let n64=input[0];let rateBp=input[1]
  if n64 < 0 or n64 > 64 or rateBp < 0 or rateBp > 1000 or length != csize_t(n64+2): return invalid
  let n=int(n64)
  for t in 0..<n:
    if input[t+2] < -1_000_000 or input[t+2] > 1_000_000: return invalid
  let rate=float64(rateBp)/10000.0
  var total=0.0
  for t in 0..<n:
    let term=float64(input[t+2])/pow(1.0+rate,float64(t))
    total=total+term
  total
