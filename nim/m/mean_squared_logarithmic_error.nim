const InvalidResult = -1.0e300
const Scale = 1_000_000.0
proc mean_squared_logarithmic_error*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "mean_squared_logarithmic_error".} =
  if values==nil or length<1:return InvalidResult
  let n0=values[0];if n0<1 or n0>64:return InvalidResult
  let n=int(n0);if length!=1+2*n:return InvalidResult
  for i in 0..<2*n:
    let x=values[1+i];if x< -999999 or x>1_000_000:return InvalidResult
  var total=0.0
  for i in 0..<n:
    let t=float64(values[1+i])/Scale;let p=float64(values[1+n+i])/Scale
    let d=ln(1.0+t)-ln(1.0+p);total+=d*d
  return total/float64(n)
