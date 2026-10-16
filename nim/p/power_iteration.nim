import math
proc power_iteration*(v: ptr int64,n:uint64):float64 {.cdecl,exportc:"power_iteration".}=
  if v==nil or n!=5:return -1e300
  for i in 0..4:if v[i]<1 or v[i]>1000:return -1e300
  let a=float64(v[0]);let b=float64(v[1]);let d=float64(v[2]);if a*d<=b*b:return -1e300
  var x=float64(v[3]);var y=float64(v[4]);var previous=0.0
  for it in 0..99:
    let w0=a*x+b*y;let w1=b*x+d*y;let norm=sqrt(w0*w0+w1*w1);if norm==0:return -1e300
    x=w0/norm;y=w1/norm;let av0=a*x+b*y;let av1=b*x+d*y;let eigenvalue=x*av0+y*av1
    if abs(eigenvalue-previous)/eigenvalue<=1e-12 or it==99:return eigenvalue
    previous=eigenvalue
  -1e300
