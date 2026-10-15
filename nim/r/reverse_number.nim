const MaxInput = 1_000_000_000'i64

proc reverse_number*(number: int64): int64 {.cdecl, exportc: "reverse_number".} =
  if number < 0 or number > MaxInput: return -1
  var current = number
  var reversed = 0'i64
  while current > 0:
    reversed = reversed * 10 + current mod 10
    current = current div 10
  reversed
