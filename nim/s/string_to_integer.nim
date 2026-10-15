## Parse an ASCII byte sequence like C atoi, clamping to signed 32-bit bounds.
const MaxInputLength = 4096
const Int32MaxValue = 2147483647'i64
const Int32MinMagnitude = 2147483648'i64

proc string_to_integer*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "string_to_integer".} =
  if length > csize_t(MaxInputLength) or (length != 0 and input == nil): return -2
  for position in 0 ..< int(length):
    if input[position] < 1 or input[position] > 127: return -2

  var index = 0
  while index < int(length) and input[index] == 32: inc index
  var negative = false
  if index < int(length) and (input[index] == 43 or input[index] == 45):
    negative = input[index] == 45
    inc index
  let limit = if negative: Int32MinMagnitude else: Int32MaxValue
  var magnitude = 0'i64
  while index < int(length) and input[index] >= 48 and input[index] <= 57:
    let digit = input[index] - 48
    if magnitude > limit div 10 or (magnitude == limit div 10 and digit > limit mod 10):
      return if negative: -Int32MinMagnitude else: Int32MaxValue
    magnitude = magnitude * 10 + digit
    inc index
  if negative: -magnitude else: magnitude
