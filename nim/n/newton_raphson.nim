proc newtonRaphson*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "newton_raphson".} =
  if values == nil or length != 2: return -1.0e300
  let n=values[0]; let q=values[1]
  if n<2 or n>4 or q<4 or q>8: return -1.0e300
  var x=q.float64/4.0
  for _ in 0..<8: x=0.5*(x+n.float64/x)
  x
