const MaxOutputBytes = 41

proc balanced_ternary_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "balanced_ternary_conversion".} =
  if input.isNil or length != csize_t(1): return -1
  var reversed: array[MaxOutputBytes, uint8]
  var digitCount = 0
  var value = input[0]
  if value == 0:
    reversed[digitCount] = uint8(ord('0'))
    inc digitCount
  while value != 0:
    var quotient = value div 3
    let remainder = value mod 3
    var digit: uint8
    if remainder == 2:
      digit = uint8(ord('Z'))
      inc quotient
    elif remainder == -2:
      digit = uint8(ord('1'))
      dec quotient
    elif remainder == -1:
      digit = uint8(ord('Z'))
    elif remainder == 0:
      digit = uint8(ord('0'))
    else:
      digit = uint8(ord('1'))
    reversed[digitCount] = digit
    inc digitCount
    value = quotient
  if output.isNil or capacity < csize_t(digitCount): return -2
  for index in 0 ..< digitCount:
    output[index] = reversed[digitCount - index - 1]
  int64(digitCount)
