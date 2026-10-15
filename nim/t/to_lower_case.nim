## Lowercase ASCII bytes without locale-dependent character handling.
const MaxLength = 4096

proc to_lower_case*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "to_lower_case".} =
  if length > csize_t(MaxLength): return -1
  for index in 0 ..< int(length):
    if input[index] < 1 or input[index] > 127: return -1
  if outputCapacity < length: return -2
  for index in 0 ..< int(length):
    var value = input[index]
    if value >= 65 and value <= 90: value += 32
    output[index] = uint8(value)
  int64(length)
