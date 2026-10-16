const MaxLimit = 1_000_000'i64

proc isDecimalPalindrome(value: int64): bool =
  var remaining = value
  var reversed = 0'i64
  while remaining > 0:
    reversed = reversed * 10 + remaining mod 10
    remaining = remaining div 10
  reversed == value

proc isBinaryPalindrome(value: int64): bool =
  var remaining = value
  var reversed = 0'i64
  while remaining > 0:
    reversed = reversed * 2 + remaining mod 2
    remaining = remaining div 2
  reversed == value

proc problem36*(limit: int64): int64 {.cdecl, exportc: "problem36".} =
  if limit < 0 or limit > MaxLimit: return -1
  var total = 0'i64
  var value = 1'i64
  while value < limit:
    if isDecimalPalindrome(value) and isBinaryPalindrome(value):
      total += value
    value += 1
  total
