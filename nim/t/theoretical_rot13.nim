## Apply ROT13 only to lowercase non-NUL ASCII bytes.
proc theoreticalRot13*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "theoretical_rot13".} =
  if length > 66: return -1
  for index in 0 ..< int(length):
    if input[index] < 1 or input[index] > 127: return -1
  if outputCapacity < length: return -2
  for index in 0 ..< int(length):
    let value = input[index]
    let mapped = if value >= ord('a') and value <= ord('z'):
      int64(ord('a')) + (value - int64(ord('a')) + 13) mod 26
    else:
      value
    output[index] = uint8(mapped)
  int64(length)
