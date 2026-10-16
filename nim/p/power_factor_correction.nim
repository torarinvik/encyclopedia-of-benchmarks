import std/math
proc power_factor_correction*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "power_factor_correction".} =
  if v == nil or n != 6: return -1.0e300
  let op=v[0]; let voltage=v[1]; let frequency=v[2]; let power=v[3]; let cb=v[4]; let eb=v[5]
  if (op != 0 and op != 1) or voltage < 1 or voltage > 1000 or frequency < 1 or frequency > 1000 or power < -1000000 or power > 1000000 or cb < -10000 or cb > 10000 or eb < -10000 or eb > 10000 or cb == 0 or eb == 0 or (op == 1 and cb == eb): return -1.0e300
  let c=float64(cb)/10000.0; let e=float64(eb)/10000.0; let p=float64(power)
  let dq=(p/c)*sin(arccos(c))-(p/e)*sin(arccos(e))
  if op == 0: return dq/(2.0*PI*float64(frequency)*float64(voltage)*float64(voltage))
  float64(voltage)*float64(voltage)/(2.0*PI*float64(frequency)*dq)
