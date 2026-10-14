## Convert a nonnegative signed 64-bit value with a LIFO digit stack.
proc decimal_to_any_using_stack*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "decimal_to_any_using_stack".} =
  if input == nil or length != 2: return -1
  let value = input[0]
  let base = input[1]
  if value < 0 or base < 2 or base > 16: return -1
  var width = csize_t(1)
  var remaining = value
  while remaining >= base:
    remaining = remaining div base
    inc width
  if output == nil or outputCapacity < width: return -2
  var top = csize_t(0)
  remaining = value
  if remaining == 0:
    output[top] = uint8(ord('0'))
    inc top
  while remaining > 0:
    let digit = remaining mod base
    if digit < 10:
      output[top] = uint8(ord('0') + int(digit))
    else:
      output[top] = uint8(ord('A') + int(digit) - 10)
    inc top
    remaining = remaining div base
  var left = csize_t(0)
  var right = top - 1
  while left < right:
    swap(output[left], output[right])
    inc left
    dec right
  int64(top)
