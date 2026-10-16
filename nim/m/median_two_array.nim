proc median_two_array*(a: ptr UncheckedArray[int64], length: csize_t): float64 {.cdecl, exportc: "median_two_array".} =
  const bad = -1.0e300
  if a.isNil or length < 2 or length > 259 or a[0] < 0 or a[1] < 0 or a[0]+a[1] < 1 or a[0]+a[1] > 256 or length != csize_t(a[0]+a[1]+2): return bad
  let n=int(a[0]+a[1]);let n1=int(a[0]);var vals:array[256,int64]
  for i in 0..<n:
    vals[i]=a[i+2]
    if vals[i] < -1000000 or vals[i] > 1000000: return bad
    if i<n1 and i>0 and vals[i]<vals[i-1]: return bad
    if i>=n1 and i>n1 and vals[i]<vals[i-1]: return bad
  for i in 1..<n:
    let x=vals[i];var j=i
    while j>0 and vals[j-1]>x: vals[j]=vals[j-1];dec j
    vals[j]=x
  let m=n div 2
  if n mod 2==1: float64(vals[m]) else: (float64(vals[m-1])+float64(vals[m]))/2.0
