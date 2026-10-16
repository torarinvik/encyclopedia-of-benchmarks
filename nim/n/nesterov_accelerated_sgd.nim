proc putDouble(outp:ptr UncheckedArray[uint8],off:int,x:float64)=
 let bits=cast[uint64](x)
 for k in 0..<8:outp[off+k]=uint8((bits shr (8*k)) and 255)
proc nesterov_accelerated_sgd*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"nesterov_accelerated_sgd".}=
 if v==nil or n<4:return -1
 let wi=v[0];let si=v[1];let lm=v[2];let mm=v[3]
 if wi<1 or wi>8 or si<1 or si>8 or lm<0 or lm>1000 or mm<0 or mm>1000 or n!=csize_t(4+wi*(si+1)):return -1
 let w=int(wi);let s=int(si)
 for i in 4..<int(n):if v[i] < -10000 or v[i]>10000:return -1
 if outp==nil or cap<csize_t(w*8):return -2
 var p:array[8,float64];var vel:array[8,float64];let lr=float64(lm)/1000.0;let m=float64(mm)/1000.0
 for i in 0..<w:p[i]=float64(v[4+i])/1000.0
 for t in 0..<s:for i in 0..<w:
  let prev=vel[i];let g=float64(v[4+w+t*w+i])/1000.0
  vel[i]=m*vel[i]-lr*g;p[i]=p[i]-m*prev+(1.0+m)*vel[i]
 for i in 0..<w:putDouble(outp,i*8,p[i])
 int64(w*8)
