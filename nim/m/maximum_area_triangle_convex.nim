# Independent draft; compilation and output are unverified.
proc triangleCross(p: ptr UncheckedArray[int64], a,b,c: int): int64 =
  let ax=p[1+2*a]; let ay=p[2+2*a]
  (p[1+2*b]-ax)*(p[2+2*c]-ay)-(p[2+2*b]-ay)*(p[1+2*c]-ax)

proc maximum_area_triangle_convex*(p: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_area_triangle_convex".} =
  if p.isNil or length==0 or p[0]<3 or p[0]>1024: return -1
  let n=int(p[0])
  if length!=csize_t(1+2*n): return -1
  for i in 1 ..< int(length):
    if p[i]< -1000000 or p[i]>1000000: return -1
  for i in 0 ..< n:
    let next=(i+1) mod n
    for j in 0 ..< n:
      if j!=i and j!=next and triangleCross(p,i,next,j)<=0: return -1
  var best=0'i64
  for i in 0 ..< n-2:
    for j in i+1 ..< n-1:
      var lo=j+1; var hi=n-1
      while lo<hi:
        let mid=lo+(hi-lo) div 2
        if triangleCross(p,i,j,mid)<triangleCross(p,i,j,mid+1): lo=mid+1
        else: hi=mid
      best=max(best,triangleCross(p,i,j,lo))
  best
