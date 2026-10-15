## Smallest base in which a nonnegative integer is palindromic.
proc isPalindromicInBase(number, base: int64): bool =
  if number <= 1: return true
  if number mod base == 0: return false
  var remaining = number
  var reversed = 0'i64
  while remaining > 0:
    reversed = reversed * base + remaining mod base
    remaining = remaining div base
  reversed == number

proc lowest_base_palindrome*(number: int64): int64 {.cdecl, exportc: "lowest_base_palindrome".} =
  if number < 0 or number > 64: return -1
  var base = 2'i64
  while not isPalindromicInBase(number, base): inc base
  base
