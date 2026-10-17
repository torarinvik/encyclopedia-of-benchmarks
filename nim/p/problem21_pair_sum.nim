proc properDivisorSum(value: int64): int64 =
  if value <= 1: return 0
  var total = 1'i64
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0:
      let partner = value div divisor
      total += divisor
      if partner != divisor: total += partner
    divisor += 1
  total

proc problem21_pair_sum*(limit: int64): int64 {.cdecl, exportc: "problem21_pair_sum".} =
  if limit < 2 or limit > 10000: return -1
  var total = 0'i64
  var smaller = 2'i64
  while smaller < limit:
    let larger = properDivisorSum(smaller)
    if larger > smaller and properDivisorSum(larger) == smaller:
      total += smaller + larger
    smaller += 1
  total
