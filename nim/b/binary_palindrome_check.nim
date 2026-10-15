## Test whether the significant binary digits of an int32 value form a palindrome.
proc binary_palindrome_check*(number: int64): int64 {.cdecl, exportc: "binary_palindrome_check".} =
  if number < int64(low(int32)) or number > int64(high(int32)): return -1
  if number < 0: return 0
  var remaining = number
  var reversed = 0'i64
  while remaining > 0:
    reversed = (reversed shl 1) or (remaining and 1)
    remaining = remaining shr 1
  if reversed == number: 1 else: 0
