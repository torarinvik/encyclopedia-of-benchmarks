const bad = -1.0e300
proc extended_kalman_filter*(v: ptr UncheckedArray[int64], n: csize_t): float64 {.cdecl, exportc: "extended_kalman_filter".} =
  if v.isNil or n < 10 or n > 17: return bad
  let steps=v[0]
  if steps<1 or steps>8 or n!=csize_t(9+steps):return bad
  for i in 1..8:
    if v[i]< -10000 or v[i]>10000:return bad
  for i in 9..<int(n):
    if v[i]< -10000 or v[i]>10000:return bad
  let sc=1000.0
  var x=float64(v[1])/sc;var y=float64(v[2])/sc;var p00=float64(v[3])/sc;var p01=float64(v[4])/sc;var p11=float64(v[5])/sc
  let q0=float64(v[6])/sc;let q1=float64(v[7])/sc;let r=float64(v[8])/sc
  if v[1]< -2000 or v[1]>2000 or v[2]< -2000 or v[2]>2000 or p00<=0 or p11<=0 or p00*p11<=p01*p01 or q0<0 or q1<0 or r<=0 or r>10:return bad
  for t in 0..<int(steps):
    let f01=0.1;let f10=0.1*x;let nx=x+f01*y;let ny=y+0.05*x*x
    let a=p00+2*f01*p01+f01*f01*p11+q0;let b=f10*p00+(1+f01*f10)*p01+f01*p11;let c=f10*f10*p00+2*f10*p01+p11+q1
    x=nx;y=ny;p00=a;p01=b;p11=c
    let h0=0.1*x;let res=float64(v[9+t])/sc-(0.05*x*x+y);let s=h0*h0*p00+2*h0*p01+p11+r
    if s<=0:return bad
    let k0=(p00*h0+p01)/s;let k1=(p01*h0+p11)/s;x+=k0*res;y+=k1*res
    let a00=1-k0*h0;let a01 = -k0;let a10 = -k1*h0;let a11=1-k1
    let z00=a00*a00*p00+2*a00*a01*p01+a01*a01*p11+k0*k0*r
    let z01=a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r
    let z11=a10*a10*p00+2*a10*a11*p01+a11*a11*p11+k1*k1*r
    p00=z00;p01=z01;p11=z11
  return x
