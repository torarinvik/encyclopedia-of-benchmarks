proc gcdI64(left, right: int64): int64 =
  var a = left
  var b = right
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc problem33*(digitLen: int64): int64 {.cdecl, exportc: "problem33".} =
  if digitLen < 0 or digitLen > 5: return -1
  var upper = 1'i64
  for _ in 0 ..< digitLen: upper *= 10
  var product = 1.0
  var denominator = 11'i64
  for numerator in 11'i64 ..< upper:
    while denominator <= 99:
      if numerator != denominator and numerator mod 10 == denominator div 10 and denominator mod 10 != 0 and
          float64(numerator div 10) / float64(denominator mod 10) == float64(numerator) / float64(denominator):
        let divisor = gcdI64(numerator, denominator)
        product *= float64(denominator div divisor) / float64(numerator div divisor)
      denominator += 1
    denominator = 10
  int64(product)
