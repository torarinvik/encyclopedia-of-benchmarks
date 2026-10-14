## Reverse half the digits to avoid overflow.
proc palindrome_number*(value: int64): int64 {.cdecl, exportc: "palindrome_number".} =
  if value < 0 or value > 2147483647'i64: return -1
  if value != 0 and value mod 10 == 0: return 0
  var remaining = value
  var reversedHalf: int64 = 0
  while remaining > reversedHalf:
    reversedHalf = reversedHalf * 10 + remaining mod 10
    remaining = remaining div 10
  if remaining == reversedHalf or remaining == reversedHalf div 10: 1 else: 0
