proc putF64(o:ptr UncheckedArray[uint8],p:int,x:float64)=
  let b=cast[uint64](x)
  for k in 0..<8:o[p+k]=uint8((b shr (8*k)) and 255)
proc gaussian_elimination_pivoting*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"gaussian_elimination_pivoting".}=
  if v==nil or n<1 or n>21:return -1
  let d=v[0]
  if d<2 or d>4 or n!=csize_t(1+d*(d+1)):return -1
  var a:array[4,array[5,float64]]
  for i in 0..<int(d):
    for j in 0..int(d):
      let z=v[1+i*(int(d)+1)+j]
      if z < -10000 or z>10000:return -1
      a[i][j]=float64(z)/1000.0
  let bytes=int(d)*8
  
  for col in 0..<int(d):
    for i in col..<int(d):
      if abs(a[i][col])>abs(a[col][col]):swap(a[i],a[col])
    if abs(a[col][col])<1e-8:return -1
    if col>0:
      let prior=col-1
      for i in col..<int(d):
        let f=a[i][prior]/a[prior][prior]
        for j in 0..int(d):a[i][j]-=f*a[prior][j]
  var x:array[4,float64]
  for col in countdown(int(d)-1,0):
    x[col]=a[col][int(d)]/a[col][col]
    if col>0:
      for i in countdown(col-1,0):a[i][int(d)]-=a[i][col]*x[col]
  if o==nil or cap<csize_t(bytes):return -2
  for i in 0..<int(d):putF64(o,i*8,x[i])
  int64(bytes)
