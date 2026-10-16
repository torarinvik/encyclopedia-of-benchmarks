import std/math
const Bad = -1.0e300
proc fact(n: int64): float64 =
  result = 1.0
  for i in 2'i64 .. n:
    result *= float64(i)
proc term(m: int64, x: float64, i: int64): float64 =
  var e: int64
  var sign = 1.0
  if m == 0:
    e = i
  elif m == 1:
    e = 2 * i + 1
    if i mod 2 != 0: sign = -1.0
  else:
    e = 2 * i
    if i mod 2 != 0: sign = -1.0
  if m == 0: pow(x, float64(e)) / fact(e)
  else: sign / fact(e) * pow(x, float64(e))
proc maclaurin*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "maclaurin".} =
  if v == nil or n != 3: return Bad
  let m = v[0]
  let xm = v[1]
  let em = v[2]
  if m < 0 or m > 2 or xm < -2000 or xm > 2000 or em < 1 or em > 250: return Bad
  let x = float64(xm) / 1000.0
  let error = float64(em) / 1000.0
  var coefficient = 0.0
  var accumulated = 0.0
  for i in 0'i64 ..< 32:
    accumulated += coefficient
    coefficient = term(m, x, i)
    if abs(coefficient) <= error: return accumulated
  Bad
