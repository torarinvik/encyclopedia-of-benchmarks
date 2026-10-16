proc divisorCount(value: int64): int64 =
  var remaining = value
  var factor = 2'i64
  var count = 1'i64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      var exponent = 0'i64
      while remaining mod factor == 0:
        remaining = remaining div factor
        inc exponent
      count *= exponent + 1
    inc factor
  if remaining > 1: count *= 2
  count

proc problem12*(minimumDivisors: int64): int64 {.cdecl, exportc: "problem12".} =
  if minimumDivisors < 0 or minimumDivisors > 500: return -1
  for index in 1'i64..12_375'i64:
    var left = index
    var right = index + 1
    if index mod 2 == 0: left = left div 2 else: right = right div 2
    if divisorCount(left) * divisorCount(right) >= minimumDivisors:
      return index * (index + 1) div 2
  -1
