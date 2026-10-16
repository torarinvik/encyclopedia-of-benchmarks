## Cross-platform scalar implementation of gross_profit_margin.
const InvalidResult = -1.0e300

proc gross_profit_margin*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gross_profit_margin".} =
  if values == nil or length != csize_t(2): return InvalidResult
  let revenue = values[0]
  let cost = values[1]
  if revenue < 1 or revenue > 1000000 or cost < 0 or cost > 1000000: return InvalidResult
  (float64(revenue) - float64(cost)) / float64(revenue)
