## Reverse bytes by swapping inward from both ends.
const MaxLength = 4096

proc reverse_string_in_place*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_string_in_place".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] < 0 or input[index] > 255: return -1
  if outputCapacity < length or (length != 0 and output == nil): return -2
  for index in 0 ..< int(length): output[index] = uint8(input[index])
  var left: csize_t = 0
  var right = length
  while left < right:
    dec right
    if left >= right: break
    swap(output[left], output[right])
    inc left
  int64(length)
