proc putF64(o:ptr UncheckedArray[uint8],p:int,x:float64)=
  let bits=cast[uint64](x)
  for k in 0..<8:o[p+k]=uint8((bits shr (8*k)) and 255)
proc gauss_jordan*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"gauss_jordan".}=
  if v==nil or n<2 or n>22:return -1
  let r=v[0];let c=v[1]
  if r<1 or r>4 or c<1 or c>4 or n!=csize_t(2+r*c+r):return -1
  var a:array[4,array[4,float64]];var b:array[4,float64]
  for i in 0..<int(r):
    for j in 0..<int(c):
      let z=v[2+i*int(c)+j]
      if z < -5000 or z>5000:return -1
      a[i][j]=float64(z)/1000.0
    let z=v[2+int(r*c)+i]
    if z < -5000 or z>5000:return -1
    b[i]=float64(z)/1000.0
  let bytes=int(r*c+r)*8
  if o==nil or cap<csize_t(bytes):return -2
  for col in 0..<int(c):
    var pivot = -1
    for row in col..<int(r):
      if abs(a[row][col])>1e-8:pivot=row;break
    if pivot<0:continue
    if pivot!=col:swap(a[pivot],a[col]);swap(b[pivot],b[col])
    let pv=a[col][col]
    for j in 0..<int(c):a[col][j]/=pv
    b[col]/=pv
    for row in 0..<int(r):
      if row==col:continue
      let factor=a[row][col]
      for j in 0..<int(c):a[row][j]-=factor*a[col][j]
      b[row]-=factor*b[col]
  var at=0
  for i in 0..<int(r):
    for j in 0..<int(c):putF64(o,at*8,a[i][j]);inc at
  for i in 0..<int(r):putF64(o,at*8,b[i]);inc at
  int64(bytes)
