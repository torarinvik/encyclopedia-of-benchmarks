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

proc problem21*(limit: int64): int64 {.cdecl, exportc: "problem21".} =
  if limit < 1 or limit > 10000: return -1
  var total = 0'i64
  var value = 1'i64
  while value < limit:
    let partner = properDivisorSum(value)
    if partner != value and properDivisorSum(partner) == value: total += value
    value += 1
  total
