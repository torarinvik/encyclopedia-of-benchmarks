proc ncr_combinations*(total, choose: float64): float64
    {.cdecl, exportc: "ncr_combinations".} =
  const invalidResult = -1.0e300
  if total != total or choose != choose or total < 0.0 or total > 20.0 or
      choose < 0.0 or choose > 12.0 or choose != float64(int64(choose)):
    return invalidResult

  let count = int64(choose)
  var numerator = 1.0
  for index in 0 ..< int(count):
    numerator *= total - float64(index)
  var denominator = 1.0
  for factor in 2 .. int(count):
    denominator *= float64(factor)
  numerator / denominator
