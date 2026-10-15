## Newton's second law: net force equals mass times acceleration.
proc newtons_second_law_of_motion*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "newtons_second_law_of_motion".} =
  if length != 2 or values == nil: return -1.0e300
  let mass = values[0]
  let acceleration = values[1]
  if mass < -1000 or mass > 1000 or acceleration < -1000 or acceleration > 1000:
    return -1.0e300
  float64(mass) * float64(acceleration)
