const MaxTerms = 64
const MaxWords = 66
const ValueLimit = 1_000_000'i64

proc aitkenGcd(leftValue, rightValue: uint64): uint64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc aitkenStoreI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc aitken_delta_squared_sequence_transform*(values: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "aitken_delta_squared_sequence_transform".} =
  if values.isNil or length < 3 or length > MaxWords: return -1
  let nValue = values[0]
  if nValue < 2 or nValue > MaxTerms or int(length) != int(nValue) + 1: return -1
  let n = int(nValue)
  for index in 0 ..< n:
    if values[index + 1] < -ValueLimit or values[index + 1] > ValueLimit: return -1
  let outputLength = 16 * (n - 2)
  if output.isNil or int(outputCapacity) < outputLength: return -2

  for index in 0 ..< n - 2:
    let first = values[index + 1]
    let middle = values[index + 2]
    let last = values[index + 3]
    var numerator = first * last - middle * middle
    var denominator = first - 2 * middle + last
    if denominator == 0:
      if first == middle and middle == last:
        numerator = first
        denominator = 1
      else:
        numerator = 0
    else:
      if denominator < 0:
        numerator = -numerator
        denominator = -denominator
      let magnitude = if numerator < 0: uint64(-numerator) else: uint64(numerator)
      let divisor = aitkenGcd(magnitude, uint64(denominator))
      numerator = numerator div int64(divisor)
      denominator = denominator div int64(divisor)
    aitkenStoreI64(output, index * 16, numerator)
    aitkenStoreI64(output, index * 16 + 8, denominator)
  int64(outputLength)
