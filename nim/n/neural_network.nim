import math
proc putd(o:ptr UncheckedArray[uint8],p:int,x:float64)=
 let b=cast[uint64](x)
 for k in 0..<8:o[p+k]=uint8((b shr (8*k)) and 255)
proc sig(x:float64):float64=1.0/(1.0+exp(-x))
proc neural_network*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"neural_network".}=
 if v==nil or n<7:return -1
 let ni=v[0];let nh=v[1];let no=v[2]
 if ni<1 or ni>3 or nh<1 or nh>3 or no<1 or no>3 or n!=3+int(ni)+int(ni*nh)+int(nh*no):return -1
 for i in 3..<int(n):if v[i] < -1000 or v[i]>1000:return -1
 if o==nil or cap<int(no)*8:return -2
 let xs=3;let w1=xs+int(ni);let w2=w1+int(ni*nh)
 var h:array[3,float64]
 for j in 0..<int(nh):
  var z=0.0
  for i in 0..<int(ni):z+=float64(v[xs+i])/1000.0*(float64(v[w1+i*int(nh)+j])/1000.0)
  h[j]=sig(z)
 for j in 0..<int(no):
  var z=0.0
  for i in 0..<int(nh):z+=h[i]*(float64(v[w2+i*int(no)+j])/1000.0)
  putd(o,j*8,sig(z))
 int64(no*8)
