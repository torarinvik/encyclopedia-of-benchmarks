import math
proc star_delta_conversions*(v:ptr int64,n:uint64):int64 {.cdecl,exportc.}=
 if v==nil or n!=4 or (v[0]!=0 and v[0]!=1):return -1
 for i in 1..3:if v[i]<1000 or v[i]>100000:return -1
 let a=float64(v[1]);let b=float64(v[2]);let c=float64(v[3]);var outp:array[3,float64]
 if v[0]==0:
  let p=a*b+b*c+c*a;outp=[p/a,p/b,p/c]
 else:
  let s=a+b+c;outp=[b*c/s,c*a/s,a*b/s]
 var h=0xcbf29ce484222325'u64
 for value in outp:
  let q=int64(floor(value+0.5));let u=cast[uint64](q)
  for j in 0..7:h=(h xor ((u shr (8*j)) and 255'u64))*%0x100000001b3'u64
 cast[int64](h)
