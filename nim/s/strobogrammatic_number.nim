const MaxInputLength = 64

proc rotatedDigit(value: int64): int64 =
  case value
  of 48: 48
  of 49: 49
  of 54: 57
  of 56: 56
  of 57: 54
  else: -1

proc strobogrammatic_number*(bytes: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "strobogrammatic_number".} =
  if (bytes == nil and length != 0) or length > csize_t(MaxInputLength): return -1
  for index in 0 ..< int(length):
    if bytes[index] < 0 or bytes[index] > 127: return -1
  var left = 0
  var right = int(length)
  while left < right:
    dec right
    if rotatedDigit(bytes[left]) != bytes[right]: return 0
    inc left
  1
