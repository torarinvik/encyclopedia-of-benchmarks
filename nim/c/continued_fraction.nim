proc gcdPositive(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc continuedFraction*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "continued_fraction".} =
  if input == nil or length != 2: return -1
  var numerator = input[0]
  var denominator = input[1]
  if numerator < -1_000_000 or numerator > 1_000_000 or denominator < -1_000_000 or
      denominator > 1_000_000 or denominator == 0: return -1
  let divisor = gcdPositive(abs(numerator), abs(denominator))
  numerator = numerator div divisor
  denominator = denominator div divisor
  if denominator < 0:
    numerator = -numerator
    denominator = -denominator
  var coefficients: array[32, int64]
  var count = 0
  while true:
    var quotient = numerator div denominator
    var remainder = numerator mod denominator
    if remainder < 0:
      dec quotient
      remainder += denominator
    if count == coefficients.len: return -1
    coefficients[count] = quotient
    inc count
    if remainder == 0: break
    numerator = denominator
    denominator = remainder
  let bytes = count * 8
  if csize_t(bytes) > capacity or output == nil: return -2
  for index in 0 ..< count:
    let bits = cast[uint64](coefficients[index])
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(bytes)
