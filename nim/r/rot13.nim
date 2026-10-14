## Apply case-preserving ROT13 to a non-NUL ASCII byte sequence.
proc rot13*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rot13".} =
  if length > 66: return -1
  for index in 0 ..< int(length):
    if input[index] < 1 or input[index] > 127: return -1
  if outputCapacity < length: return -2
  for index in 0 ..< int(length):
    let value = input[index]
    var mapped = value
    if value >= ord('A') and value <= ord('Z'):
      mapped = int64(ord('A')) + (value - int64(ord('A')) + 13) mod 26
    elif value >= ord('a') and value <= ord('z'):
      mapped = int64(ord('a')) + (value - int64(ord('a')) + 13) mod 26
    output[index] = uint8(mapped)
  int64(length)
