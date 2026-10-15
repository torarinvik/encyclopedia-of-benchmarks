## Equivalent capacitance for series and parallel connections.
proc capacitor_equivalence*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "capacitor_equivalence".} =
  if values == nil or length < 2 or length > 33: return -1.0e300
  let operation = values[0]
  if operation != 0 and operation != 1: return -1.0e300
  var accumulated = 0.0
  for index in 1 ..< int(length):
    let capacitor = values[index]
    if (operation == 0 and capacitor < 0) or (operation == 1 and capacitor < 1) or capacitor > 1000:
      return -1.0e300
    if operation == 0:
      accumulated += float64(capacitor)
    else:
      accumulated += 1.0 / float64(capacitor)
  if operation == 0: return accumulated
  1.0 / accumulated
