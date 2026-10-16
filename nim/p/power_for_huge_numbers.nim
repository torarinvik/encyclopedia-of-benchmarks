const MaxOutputBytes = 513

proc power_for_huge_numbers*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "power_for_huge_numbers".} =
  if input.isNil or length != 2: return -1
  let base = input[0]
  let exponent = input[1]
  if base < 1 or base > 10000 or exponent < 0 or exponent > 128: return -1
  var digits: array[MaxOutputBytes, uint8]
  digits[0] = 1'u8
  var digitCount = 1
  var power = 0'i64
  while power < exponent:
    var carry = 0'i64
    for i in 0 ..< digitCount:
      let product = digits[i].int64 * base + carry
      digits[i] = uint8(product mod 10)
      carry = product div 10
    while carry != 0:
      if digitCount == MaxOutputBytes: return -1
      digits[digitCount] = uint8(carry mod 10)
      inc digitCount
      carry = carry div 10
    inc power
  if output.isNil or capacity < digitCount: return -2
  for i in 0 ..< digitCount:
    output[i] = uint8(ord('0') + int(digits[digitCount - 1 - i]))
  int64(digitCount)
