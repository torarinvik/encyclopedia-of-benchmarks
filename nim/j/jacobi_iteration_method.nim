proc putF64(o:ptr UncheckedArray[uint8],p:int,x:float64)=
  let bits=cast[uint64](x)
  for k in 0..<8:o[p+k]=uint8((bits shr (8*k)) and 255)
proc jacobi_iteration_method*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"jacobi_iteration_method".}=
  if v==nil or n<2 or n>26:return -1
  let d=v[0];let it=v[1]
  if d<2 or d>4 or it<1 or it>8 or n!=csize_t(2+d*d+2*d):return -1
  var a:array[4,array[4,float64]];var b,x,y:array[4,float64]
  let rhs=2+int(d*d);let ini=rhs+int(d)
  for i in 0..<int(d):
    var off=0.0
    for j in 0..<int(d):
      let z=v[2+i*int(d)+j]
      if z<0 or z>4000:return -1
      a[i][j]=float64(z)/1000.0
      if i!=j:off+=a[i][j]
    if a[i][i]<=off:return -1
    if v[rhs+i]< -2000 or v[rhs+i]>2000 or v[ini+i]< -2000 or v[ini+i]>2000:return -1
    b[i]=float64(v[rhs+i])/1000.0;x[i]=float64(v[ini+i])/1000.0
  let bytes=int(d)*8
  if o==nil or cap<csize_t(bytes):return -2
  for _ in 0..<int(it):
    for i in 0..<int(d):
      var total=0.0
      for j in 0..<int(d):if i!=j:total+= -a[i][j]*x[j]
      y[i]=(total+b[i])/a[i][i]
    x=y
  for i in 0..<int(d):putF64(o,i*8,x[i])
  int64(bytes)
