## Return the source's extracted hexadecimal digit as a numeric nibble.
import std/math

proc modularPower16(exponentValue, modulus: int64): int64 =
  var exponent = exponentValue
  var result = 1'i64 mod modulus
  var base = 16'i64 mod modulus
  while exponent > 0:
    if (exponent and 1) != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1
  result

proc bbpSubsum(position, addend: int64): float64 =
  var total = 0.0
  var index = 0'i64
  while index < position + 1000:
    let denominator = 8 * index + addend
    let exponent = position - 1 - index
    let term = if index < position:
      float64(modularPower16(exponent, denominator)) / float64(denominator)
    else:
      pow(16.0, float64(exponent)) / float64(denominator)
    total += term
    inc index
  total

proc bailey_borwein_plouffe*(position: int64): int64 {.cdecl, exportc: "bailey_borwein_plouffe".} =
  if position < 1 or position > 10: return -1
  let sumResult = 4.0 * bbpSubsum(position, 1) - 2.0 * bbpSubsum(position, 4)
    - bbpSubsum(position, 5) - bbpSubsum(position, 6)
  let fractional = sumResult - floor(sumResult)
  int64(fractional * 16.0)
