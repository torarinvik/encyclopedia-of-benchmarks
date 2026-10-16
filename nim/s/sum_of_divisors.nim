## Return the sum of all positive divisors of n by prime factorization.
proc sum_of_divisors*(n: int64): int64 {.cdecl, exportc: "sum_of_divisors".} =
  if n < 1 or n > 1000000: return -1
  var remaining = n
  var sigma = 1'i64
  var factor = 2'i64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      var power = 1'i64
      var geometricSum = 1'i64
      while remaining mod factor == 0:
        remaining = remaining div factor
        power *= factor
        geometricSum += power
      sigma *= geometricSum
    inc factor
  if remaining > 1: sigma *= remaining + 1
  sigma
