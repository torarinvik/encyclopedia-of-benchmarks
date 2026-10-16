proc problem3*(number: int64): int64 {.cdecl, exportc: "problem3".} =
  if number < 2 or number > 600_851_475_143: return -1
  var remaining = number
  var largest = 1'i64
  var factor = 2'i64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      largest = factor
      remaining = remaining div factor
    else:
      inc factor
  if remaining > 1: remaining else: largest
