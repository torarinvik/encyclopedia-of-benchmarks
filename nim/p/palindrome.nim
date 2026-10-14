## Check whether an exact ASCII string is a palindrome.
proc palindrome*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "palindrome".} =
  if length > 4096: return -1
  var index = csize_t(0)
  while index < length:
    if values[index] < 0 or values[index] > 127: return -1
    inc index
  var left = csize_t(0)
  while left < length div 2:
    if values[left] != values[length - 1 - left]: return 0
    inc left
  1
