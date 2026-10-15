## Check whether an ASCII string is a palindrome ignoring ASCII letter case.
proc asciiLower(value: int64): int64 =
  if value >= 65 and value <= 90: value + 32
  else: value

proc case_insensitive_palindrome*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "case_insensitive_palindrome".} =
  if length > 4096: return -1
  var index = csize_t(0)
  while index < length:
    if values[index] < 0 or values[index] > 127: return -1
    inc index
  var left = csize_t(0)
  while left < length div 2:
    if asciiLower(values[left]) != asciiLower(values[length - 1 - left]): return 0
    inc left
  1
