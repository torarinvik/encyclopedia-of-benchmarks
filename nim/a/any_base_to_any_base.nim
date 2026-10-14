## Convert a radix digit array through checked decimal accumulation.
proc any_base_to_any_base*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "any_base_to_any_base".} =
  if input == nil or length < 3 or length > 65: return -1
  let sourceBase = input[0]
  let targetBase = input[1]
  if sourceBase < 2 or sourceBase > 36 or targetBase < 2 or targetBase > 36: return -1
  var value: int64 = 0
  var index = csize_t(2)
  while index < length:
    let digit = input[index]
    if digit < 0 or digit >= sourceBase: return -1
    if value > (high(int64) - digit) div sourceBase: return -1
    value = value * sourceBase + digit
    inc index
  var width = csize_t(1)
  var remaining = value
  while remaining >= targetBase:
    remaining = remaining div targetBase
    inc width
  if output == nil or outputCapacity < width: return -2
  var top = csize_t(0)
  remaining = value
  if remaining == 0:
    output[top] = uint8(ord('0')); inc top
  while remaining > 0:
    let digit = remaining mod targetBase
    if digit < 10:
      output[top] = uint8(ord('0') + int(digit))
    else:
      output[top] = uint8(ord('A') + int(digit) - 10)
    inc top
    remaining = remaining div targetBase
  var left = csize_t(0)
  var right = top - 1
  while left < right:
    swap(output[left], output[right])
    inc left; dec right
  int64(top)
