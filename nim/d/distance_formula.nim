## Compute the Euclidean distance with the pinned Java coordinate expression.
import math

proc distance_formula*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "distance_formula".} =
  if values == nil or length != 4: return -1.0e300
  for i in 0 ..< 4:
    if values[i] < -1_000_000 or values[i] > 1_000_000: return -1.0e300
  let dx = float64(values[2] - values[0])
  let dy = float64(values[3] - values[0])
  sqrt(dx * dx + dy * dy)
