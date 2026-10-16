const Invalid = -1.0e300
proc gradient_descent*(v: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "gradient_descent".} =
 if v == nil or length < 5 or length > 68: return Invalid
 let d=v[0]; let selected=v[1]; let rate=v[2]; let iterations=v[3]
 if d<1 or d>64 or selected<0 or selected>=d or length!=csize_t(4+d) or rate<1 or rate>500000 or iterations<0 or iterations>10000: return Invalid
 var x: array[64,float64]
 for i in 0 ..< int(d):
  if v[4+i]< -10 or v[4+i]>10: return Invalid
  x[i]=float64(v[4+i])
 let alpha=float64(rate)/1_000_000.0
 for _ in 0 ..< int(iterations):
  var g: array[64,float64]
  for i in 0 ..< int(d): g[i]=2.0*x[i]
  for i in 0 ..< int(d): x[i]-=alpha*g[i]
 return x[int(selected)]
