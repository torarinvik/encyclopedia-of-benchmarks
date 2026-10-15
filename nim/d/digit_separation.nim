## Separate signed decimal digits; direction 0 is reverse and 1 is forward.
proc digit_separation*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "digit_separation".} =
  if input == nil or inputLength != 2 or (input[1] != 0 and input[1] != 1): return -1
  var remaining = input[0]
  var digits: array[20, uint8]
  var count = 0
  if remaining == 0:
    digits[0] = 0
    count = 1
  while remaining != 0:
    let remainder = remaining mod 10
    digits[count] = uint8(if remainder < 0: -remainder else: remainder)
    inc count
    remaining = remaining div 10
  if output == nil or outputCapacity < csize_t(count): return -2
  for index in 0 ..< count:
    let source = if input[1] == 0: index else: count - index - 1
    output[index] = digits[source]
  int64(count)
