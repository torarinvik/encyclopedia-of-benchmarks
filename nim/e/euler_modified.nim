proc put64(outp:ptr UncheckedArray[uint8],slot:int,x:float64)=
  let bits=cast[uint64](x)
  for k in 0..<8:outp[slot*8+k]=uint8((bits shr (8*k)) and 255)
proc euler_modified*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"euler_modified".}=
  if v==nil or n!=2:return -1
  let steps=v[0];let y0=v[1]
  if steps<1 or steps>8 or y0<1 or y0>4:return -1
  let bytes=(int(steps)+1)*8
  if outp==nil or cap<csize_t(bytes):return -2
  let h=0.25;var x=0.0;var y=float64(y0);put64(outp,0,y)
  for i in 0..<int(steps):
    let f0= -2.0*x*y*y
    let predictor=y+h*f0
    let f1= -2.0*(x+h)*predictor*predictor
    y=y+(h/2.0)*(f0+f1);x+=h;put64(outp,i+1,y)
  int64(bytes)
