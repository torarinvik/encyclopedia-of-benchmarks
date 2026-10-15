## Reverse ASCII letters while leaving every other printable byte in place.
const MaxLength = 4096

proc isAsciiLetter(value: uint8): bool =
  (value >= uint8('A') and value <= uint8('Z')) or
    (value >= uint8('a') and value <= uint8('z'))

proc reverse_only_letters*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_only_letters".} =
  if length > csize_t(MaxLength) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    if input[index] < 32 or input[index] > 126: return -1
  if outputCapacity < length or (length != 0 and output == nil): return -2
  for index in 0 ..< int(length): output[index] = uint8(input[index])

  var left: csize_t = 0
  var right = length
  while left < right:
    if not isAsciiLetter(output[left]):
      inc left
    elif not isAsciiLetter(output[right - 1]):
      dec right
    else:
      swap(output[left], output[right - 1])
      inc left
      dec right
  int64(length)
