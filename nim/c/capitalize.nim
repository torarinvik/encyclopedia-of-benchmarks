const MaxLength = 256

proc capitalize*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "capitalize".} =
  if length > csize_t(MaxLength) or (length > 0 and input == nil): return -1
  for i in 0 ..< int(length):
    if input[i] < 0 or input[i] > 127: return -1
  if capacity < length or (length > 0 and output == nil): return -2
  for i in 0 ..< int(length): output[i] = uint8(input[i])
  if length > 0 and output[0] >= uint8(ord('a')) and output[0] <= uint8(ord('z')):
    output[0] -= 32
  int64(length)
