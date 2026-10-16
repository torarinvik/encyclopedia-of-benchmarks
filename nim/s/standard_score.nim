proc standard_score*(value, mean, stdDev: float64): float64
    {.cdecl, exportc: "standard_score".} =
  let validStdDev = (stdDev >= -1_000_000.0 and stdDev <= -0.000001) or
                    (stdDev >= 0.000001 and stdDev <= 1_000_000.0)
  if not (value >= -1_000_000.0 and value <= 1_000_000.0) or
      not (mean >= -1_000_000.0 and mean <= 1_000_000.0) or not validStdDev:
    return -1e300
  (value - mean) / stdDev
