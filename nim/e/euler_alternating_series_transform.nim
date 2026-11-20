const MaxTerms = 16
const MaxWords = 18
const ValueLimit = 1_000_000'i64
const OutputBytes = 16

proc eulerGcd(leftValue, rightValue: uint64): uint64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc eulerStoreI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc euler_alternating_series_transform*(values: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "euler_alternating_series_transform".} =
  if values.isNil or length < 2 or length > MaxWords: return -1
  let nValue = values[0]
  if nValue < 1 or nValue > MaxTerms or int(length) != int(nValue) + 1: return -1
  let n = int(nValue)
  for index in 0 ..< n:
    if values[index + 1] < -ValueLimit or values[index + 1] > ValueLimit: return -1
  if output.isNil or outputCapacity < csize_t(OutputBytes): return -2

  var numerator = 0'i64
  for order in 0 ..< n:
    var difference = 0'i64
    var coefficient = 1'i64
    for index in 0 .. order:
      let term = values[order - index + 1]
      if index mod 2 == 0:
        difference += coefficient * term
      else:
        difference -= coefficient * term
      if index < order:
        coefficient = coefficient * int64(order - index) div int64(index + 1)
    let weight = 1'i64 shl (n - order - 1)
    let weighted = difference * weight
    if order mod 2 == 0:
      numerator += weighted
    else:
      numerator -= weighted

  var denominator = 1'i64 shl n
  let magnitude = if numerator < 0: uint64(-numerator) else: uint64(numerator)
  let divisor = eulerGcd(magnitude, uint64(denominator))
  numerator = numerator div int64(divisor)
  denominator = denominator div int64(divisor)
  eulerStoreI64(output, 0, numerator)
  eulerStoreI64(output, 8, denominator)
  int64(OutputBytes)
