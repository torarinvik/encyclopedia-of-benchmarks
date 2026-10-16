proc putDouble(outp: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[offset+b] = uint8((bits shr (8*b)) and 255)
proc ordinary_least_squares_regression*(v: ptr UncheckedArray[int64], n: csize_t, outp: ptr UncheckedArray[uint8], cap: csize_t): int64 {.cdecl, exportc: "ordinary_least_squares_regression".} =
  if v == nil or n < 5 or v[0] < 2 or v[0] > 32 or n != csize_t(1+2*v[0]): return -1
  let count = int(v[0]); var xs: array[32,float64]; var ys: array[32,float64]; var xm=0.0; var ym=0.0
  for i in 0 ..< count:
    let x=v[1+2*i]; let y=v[2+2*i]
    if x < -10000 or x > 10000 or y < -10000 or y > 10000: return -1
    xs[i]=float64(x); ys[i]=float64(y); xm+=xs[i]; ym+=ys[i]
  xm/=float64(count); ym/=float64(count)
  var num=0.0; var den=0.0
  for i in 0 ..< count: let dx=xs[i]-xm; num+=dx*(ys[i]-ym); den+=dx*dx
  if den==0.0: return -1
  let slope=num/den; let intercept=ym-slope*xm
  if outp==nil or cap<16: return -2
  putDouble(outp,0,intercept); putDouble(outp,8,slope); 16
