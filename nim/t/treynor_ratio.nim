## Treynor ratio: (portfolio return - risk-free rate) / beta.
proc treynor_ratio*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "treynor_ratio".} =
  if length != 3 or values == nil: return -1.0e300
  let portfolioReturn = values[0]
  let riskFreeRate = values[1]
  let beta = values[2]
  if portfolioReturn < -1000 or portfolioReturn > 1000 or
      riskFreeRate < -1000 or riskFreeRate > 1000 or
      beta < -1000 or beta > 1000 or beta == 0: return -1.0e300
  float64(portfolioReturn - riskFreeRate) / float64(beta)
