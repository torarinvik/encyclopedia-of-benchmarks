const MaxEncodedValue = 999_999_999'i64

proc anyto_any*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "anyto_any".} =
  if input == nil or length != 3: return -1
  var encoded = input[0]
  let sourceBase = input[1]
  let destinationBase = input[2]
  if encoded < 0 or encoded > MaxEncodedValue or sourceBase < 2 or sourceBase > 10 or
      destinationBase < 2 or destinationBase > 10: return -1

  var decimalValue = 0'i64
  var sourceMultiplier = 1'i64
  while encoded > 0:
    let digit = encoded mod 10
    if digit >= sourceBase: return -1
    decimalValue += digit * sourceMultiplier
    sourceMultiplier *= sourceBase
    encoded = encoded div 10

  var result = 0'i64
  var destinationMultiplier = 1'i64
  while decimalValue > 0:
    let digit = decimalValue mod destinationBase
    result += digit * destinationMultiplier
    decimalValue = decimalValue div destinationBase
    if decimalValue > 0:
      if destinationMultiplier > MaxEncodedValue div 10: return -1
      destinationMultiplier *= 10
  result
