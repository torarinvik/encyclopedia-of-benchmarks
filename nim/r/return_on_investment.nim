## Cross-platform scalar implementation of return_on_investment.
const InvalidResult = -1.0e300

proc return_on_investment*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "return_on_investment".} =
  if values == nil or length != csize_t(2): return InvalidResult
  let gain = values[0]
  let cost = values[1]
  if gain < -1000000 or gain > 1000000 or cost < 1 or cost > 1000000: return InvalidResult
  (float64(gain) - float64(cost)) / float64(cost)
