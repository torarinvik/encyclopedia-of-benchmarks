## Cross-platform scalar implementation of earnings_per_sale.
const InvalidResult = -1.0e300

proc earnings_per_sale*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "earnings_per_sale".} =
  if values == nil or length != csize_t(3): return InvalidResult
  let net_income = values[0]
  let preferred_dividend = values[1]
  let average_shares = values[2]
  if net_income < -1000000 or net_income > 1000000 or preferred_dividend < 0 or preferred_dividend > 1000000 or average_shares < 1 or average_shares > 1000000: return InvalidResult
  (float64(net_income) - float64(preferred_dividend)) / float64(average_shares)
