## Cross-platform scalar implementation of debt_to_equity.
const InvalidResult = -1.0e300

proc debt_to_equity*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "debt_to_equity".} =
  if values == nil or length != csize_t(2): return InvalidResult
  let debt = values[0]
  let equity = values[1]
  if debt < 0 or debt > 1000000 or equity < 1 or equity > 1000000: return InvalidResult
  float64(debt) / float64(equity)
