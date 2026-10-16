import math
proc putd(o:ptr UncheckedArray[uint8],p:int,x:float64)=
 let b=cast[uint64](x)
 for k in 0..<8:o[p+k]=uint8((b shr (8*k)) and 255)
proc ordinary_least_squares_regressor*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"ordinary_least_squares_regressor".}=
 if v==nil or n<6:return -1
 let nr=v[0];let f=v[1];let t=v[2]
 if nr<2 or nr>8 or f!=2 or t<1 or t>3 or n!=3+int(nr)*3+int(t)*2:return -1
 var g:array[3,array[3,float64]];var b:array[3,float64];var p=3
 for _ in 0..<int(nr):
  let x=v[p];let y=v[p+1];let z=v[p+2];p+=3
  if x < -100 or x>100 or y < -100 or y>100 or z < -1000 or z>1000:return -1
  let row=[float64(x),float64(y),1.0]
  for i in 0..2:
   b[i]+=row[i]*float64(z)
   for j in 0..2:g[i][j]+=row[i]*row[j]
 for c in 0..2:
  var q=c
  for r in c+1..2:if abs(g[r][c])>abs(g[q][c]):q=r
  if abs(g[q][c])<1e-12:return -1
  swap(g[c],g[q]);swap(b[c],b[q]);let s=g[c][c]
  for j in c..2:g[c][j]/=s
  b[c]/=s
  for r in 0..2:
   if r!=c:
    let k=g[r][c]
    for j in c..2:g[r][j]-=k*g[c][j]
    b[r]-=k*b[c]
 if o==nil or cap<int(t)*8:return -2
 for r in 0..<int(t):
  let x=v[p];let y=v[p+1];p+=2
  if x < -100 or x>100 or y < -100 or y>100:return -1
  putd(o,r*8,float64(x)*b[0]+float64(y)*b[1]+b[2])
 int64(t*8)
