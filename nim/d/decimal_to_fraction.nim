## Convert a bounded exactly representable finite decimal to a reduced fraction.
const Powers10: array[5, int64] = [1, 10, 100, 1000, 10000]
const Powers5: array[5, int64] = [1, 5, 25, 125, 625]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc gcdPositive(aInput, bInput: int64): int64 =
  var a = aInput
  var b = bInput
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc decimal_to_fraction*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "decimal_to_fraction".} =
  if values == nil or int(length) != 2: return -1
  let mantissa = values[0]
  let placesValue = values[1]
  if placesValue < 0 or placesValue > 4: return -1
  let places = int(placesValue)
  let scale = Powers10[places]
  let maximumMantissa = 1_000_000'i64 * scale
  if mantissa < -maximumMantissa or mantissa > maximumMantissa or mantissa mod Powers5[places] != 0: return -1
  if output == nil or capacity < 16: return -2

  let decimal = float64(mantissa) / float64(scale)
  var numerator: int64
  var denominator: int64 = 1
  if decimal - float64(int64(decimal)) == 0.0:
    numerator = int64(decimal)
  else:
    var digits = places
    var magnitude = if mantissa < 0: -mantissa else: mantissa
    while digits > 0 and magnitude mod 10 == 0:
      magnitude = magnitude div 10
      dec digits
    numerator = int64(decimal * float64(Powers10[digits]))
    denominator = Powers10[digits]
    let gcd = gcdPositive(if numerator < 0: -numerator else: numerator, denominator)
    numerator = numerator div gcd
    denominator = denominator div gcd
  storeI64Le(output, 0, numerator)
  storeI64Le(output, 8, denominator)
  16
