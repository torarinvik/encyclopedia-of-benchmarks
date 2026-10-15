## Inductive reactance relation over a bounded integer-valued domain.
proc ind_reactance*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "ind_reactance".} =
  if values == nil or length != 3: return -1.0e300
  let inductance = values[0]
  let frequency = values[1]
  let reactance = values[2]
  if inductance < 0 or inductance > 1000 or frequency < 0 or frequency > 1000 or reactance < 0 or reactance > 1000: return -1.0e300
  let zeros = (if inductance == 0: 1 else: 0) + (if frequency == 0: 1 else: 0) + (if reactance == 0: 1 else: 0)
  if zeros != 1: return -1.0e300
  const pi = 3.14159265358979323846
  if inductance == 0: return float64(reactance) / (2.0 * pi * float64(frequency))
  if frequency == 0: return float64(reactance) / (2.0 * pi * float64(inductance))
  2.0 * pi * float64(frequency) * float64(inductance)
