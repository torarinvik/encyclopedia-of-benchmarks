## Increment decimal digits and write their ASCII representation.
proc plus_one*(digits: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "plus_one".} =
  if length > 256 or (length > 0 and digits.isNil): return -1
  var allNines = true
  for index in 0 ..< int(length):
    if digits[index] < 0 or digits[index] > 9: return -1
    if digits[index] != 9: allNines = false
  if length > 1 and digits[0] == 0: return -1
  let outputLength = if length == 0 or allNines: length + 1 else: length
  if outputCapacity < outputLength: return -2
  if length == 0 or allNines:
    output[0] = uint8(ord('1'))
    for index in 1 ..< int(outputLength): output[index] = uint8(ord('0'))
    return int64(outputLength)
  for index in 0 ..< int(length): output[index] = uint8(ord('0') + int(digits[index]))
  for index in countdown(int(length) - 1, 0):
    if digits[index] == 9: output[index] = uint8(ord('0'))
    else:
      inc output[index]
      break
  int64(outputLength)
