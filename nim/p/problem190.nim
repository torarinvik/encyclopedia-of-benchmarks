import std/math

const MaxN = 15'i64

proc problem190*(n: int64): int64 {.cdecl, exportc: "problem190".} =
  if n < 0 or n > MaxN: return -1
  var total = 0'i64
  var m = 2'i64
  while m <= n:
    let x1 = 2.0 / float64(m + 1)
    var product = 1.0
    var i = 1'i64
    while i <= m:
      let xi = float64(i) * x1
      product *= pow(xi, float64(i))
      inc i
    total += int64(product)
    inc m
  total
