proc put64(outp:ptr UncheckedArray[uint8],slot:int,x:float64)=
  let bits=cast[uint64](x)
  for k in 0..<8:outp[slot*8+k]=uint8((bits shr (8*k)) and 255)
proc iir_filter*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"iir_filter".}=
  if v==nil or n<7 or n>26:return -1
  let order=v[0];let samples=v[1]
  if order<1 or order>3 or samples<1 or samples>16 or n!=csize_t(4+2*order+samples):return -1
  var a,b:array[4,float64];var xh,yh:array[3,float64]
  for i in 0..<4:a[i]=0;b[i]=0
  for i in 0..<3:xh[i]=0;yh[i]=0
  for i in 0..int(order):
    let av=v[2+i];let bv=v[3+int(order)+i]
    if av < -500 or av>2000 or bv < -500 or bv>500:return -1
    a[i]=float64(av)/1000.0;b[i]=float64(bv)/1000.0
  if a[0]<0.5:return -1
  for i in 0..<int(samples):
    let x=v[4+2*int(order)+i]
    if x < -1000 or x>1000:return -1
  let bytes=(int(samples))*8
  if outp==nil or cap<csize_t(bytes):return -2
  for s in 0..<int(samples):
    let x=float64(v[4+2*int(order)+s])/1000.0
    var y=0.0
    for i in 1..int(order):y+=b[i]*xh[i-1]-a[i]*yh[i-1]
    y=(y+b[0]*x)/a[0]
    var i=int(order)
    while i>1:
      dec i;xh[i]=xh[i-1];yh[i]=yh[i-1]
    xh[0]=x;yh[0]=y;put64(outp,s,y)
  int64(bytes)
