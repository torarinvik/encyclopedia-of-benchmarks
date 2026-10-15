const MaxLength = 256

proc upper*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "upper".} =
  if length > csize_t(MaxLength) or (length > 0 and input == nil): return -1
  for i in 0 ..< int(length):
    if input[i] < 0 or input[i] > 127 or input[i] == 9 or input[i] == 10 or input[i] == 11 or input[i] == 12 or input[i] == 13 or input[i] == 32: return -1
  if capacity < length or (length > 0 and output == nil): return -2
  for i in 0 ..< int(length): output[i] = uint8(input[i])
  for i in 0 ..< int(length):
    if output[i] >= uint8(ord('a')) and output[i] <= uint8(ord('z')): output[i] -= 32
  int64(length)
