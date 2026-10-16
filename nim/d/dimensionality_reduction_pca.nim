import std/math
proc dimensionality_reduction_pca*(input: ptr UncheckedArray[float64], n: csize_t,
    output: ptr UncheckedArray[float64], cap: csize_t): int64 {.cdecl, exportc: "dimensionality_reduction_pca".} =
  if input.isNil or n < 7 or input[0] != 2 or input[2] != 1 or input[1] != floor(input[1]) or input[1] < 2 or input[1] > 8: return -1
  let m = int(input[1])
  if int(n) != 3 + 2*m: return -1
  var x, y: array[8, float64]
  var mx, my = 0.0
  for i in 0..<m:
    x[i] = input[3+i]; y[i] = input[3+m+i]
    if classify(x[i]) == fcNan or classify(x[i]) == fcInf or classify(y[i]) == fcNan or classify(y[i]) == fcInf or abs(x[i]) > 1_000_000 or abs(y[i]) > 1_000_000: return -1
    mx += x[i]; my += y[i]
  mx /= float64(m); my /= float64(m)
  var a,b,d = 0.0
  for i in 0..<m:
    let dx=x[i]-mx; let dy=y[i]-my
    a+=dx*dx; b+=dx*dy; d+=dy*dy
  a/=float64(m); b/=float64(m); d/=float64(m)
  if b <= 0 or abs(a-d)+abs(b)==0: return -1
  let t=0.5*arctan2(2*b,a-d); let vx=cos(t); let vy=sin(t)
  if output.isNil or int(cap) < m: return -2
  for i in 0..<m: output[i]=vx*x[i]+vy*y[i]
  int64(m)
