## Convert a signed 64-bit integer to canonical negabinary digits.
proc base_neg2_conversion*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "base_neg2_conversion".} =
  if input == nil or length != 1: return -1
  var width = csize_t(0)
  var remaining = input[0]
  while true:
    var quotient = remaining div -2
    var digit = remaining mod -2
    if digit < 0: digit += 2; inc quotient
    remaining = quotient
    inc width
    if remaining == 0: break
  if output == nil or outputCapacity < width: return -2
  var top = csize_t(0)
  remaining = input[0]
  while true:
    var quotient = remaining div -2
    var digit = remaining mod -2
    if digit < 0: digit += 2; inc quotient
    output[top] = uint8(ord('0') + int(digit))
    inc top
    remaining = quotient
    if remaining == 0: break
  var left = csize_t(0)
  var right = top - 1
  while left < right:
    swap(output[left], output[right])
    inc left; dec right
  int64(top)
