## Emit the bounded Python P-series list as newline-delimited ASCII.
proc decimalWidth(valueInput: int64): int =
  var value = valueInput
  result = 1
  while value >= 10:
    value = value div 10
    inc result

proc appendDecimal(output: ptr UncheckedArray[uint8], positionInput: int,
                   valueInput: int64): int =
  var value = valueInput
  var digits: array[20, uint8]
  var count = 0
  while true:
    digits[count] = uint8(value mod 10)
    inc count
    value = value div 10
    if value == 0: break
  result = positionInput
  while count > 0:
    dec count
    output[result] = uint8('0') + digits[count]
    inc result

proc p_series*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "p_series".} =
  if values == nil or length != 2: return -1
  let nthTerm = values[0]
  let power = values[1]
  if nthTerm < -256 or nthTerm > 256 or power < 0 or power > 7: return -1
  if nthTerm <= 0: return 0

  var needed = 2
  var term = 2'i64
  while term <= nthTerm:
    var denominator = 1'i64
    var exponent = 0'i64
    while exponent < power:
      denominator *= term
      inc exponent
    needed += 5 + decimalWidth(denominator)
    inc term
  if output == nil or outputCapacity < csize_t(needed): return -2

  var position = 0
  output[position] = uint8('1'); inc position
  output[position] = uint8('\n'); inc position
  term = 2
  while term <= nthTerm:
    var denominator = 1'i64
    var exponent = 0'i64
    while exponent < power:
      denominator *= term
      inc exponent
    output[position] = uint8('1'); inc position
    output[position] = uint8(' '); inc position
    output[position] = uint8('/'); inc position
    output[position] = uint8(' '); inc position
    position = appendDecimal(output, position, denominator)
    output[position] = uint8('\n'); inc position
    inc term
  int64(position)
