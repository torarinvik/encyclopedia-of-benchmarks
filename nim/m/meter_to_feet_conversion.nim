proc meter_to_feet_conversion*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "meter_to_feet_conversion".} =
  if v == nil or n != 2: return -1.0e300
  let op=v[0]; let units=v[1]
  if (op != 0 and op != 1) or units < -1000000000 or units > 1000000000: return -1.0e300
  let value=float64(units)/1000.0
  if op == 0: return value*0.3048
  value/0.3048
