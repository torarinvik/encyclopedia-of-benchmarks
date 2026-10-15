## Series and parallel resistor equivalents.
proc resistor_equivalence*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "resistor_equivalence".} =
  if values == nil or length < 2 or length > 33: return -1.0e300
  let operation = values[0]
  if operation != 0 and operation != 1: return -1.0e300
  var accumulated = 0.0
  for index in 1 ..< int(length):
    let resistor = values[index]
    if (operation == 0 and resistor < 1) or (operation == 1 and resistor < 0) or resistor > 1000:
      return -1.0e300
    if operation == 0:
      accumulated += 1.0 / float64(resistor)
    else:
      accumulated += float64(resistor)
  if operation == 0: return 1.0 / accumulated
  accumulated
