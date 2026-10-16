const InvalidResult = -1.0e300
const Scale = 1_000_000.0
proc symmetric_mean_absolute_percentage_error*(values: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "symmetric_mean_absolute_percentage_error".} =
  if values==nil or length<1:return InvalidResult
  let n0=values[0];if n0<1 or n0>64:return InvalidResult
  let n=int(n0);if length!=1+2*n:return InvalidResult
  for i in 0..<2*n:
    let x=values[1+i];if x< -1000000 or x>1_000_000:return InvalidResult
  var total=0.0
  for i in 0..<n:
    let t=float64(values[1+i])/Scale;let p=float64(values[1+n+i])/Scale
    var d=(abs(t)+abs(p))/2.0;if d==0.0:d=1e-15;total+=abs(t-p)/d
  return total/float64(n)
