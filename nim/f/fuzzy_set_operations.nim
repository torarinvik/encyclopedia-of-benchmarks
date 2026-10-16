import math
proc putd(o:ptr UncheckedArray[uint8],p:int,x:float64)=
 let b=cast[uint64](x)
 for k in 0..<8:o[p+k]=uint8((b shr (8*k)) and 255)
proc fuzzy_set_operations*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"fuzzy_set_operations".}=
 if v==nil or n<8:return -1
 let op=v[0];let m=v[1]
 if op<0 or op>8 or m<1 or m>8 or n!=5+3*int(m):return -1
 for i in 5..<int(n):if v[i]<0 or v[i]>1000:return -1
 let l=v[2];let p=v[3];let r=v[4]
 if op==0:
  if l<0 or p<l or r<p or r>1000:return -1
  for i in 0..<int(m):if v[5+int(m)+i]!=0 or v[5+2*int(m)+i]!=0:return -1
 else:
  if l!=0 or p!=0 or r!=0:return -1
  for i in 0..<int(m):if v[5+i]!=0:return -1
 if o==nil or cap<int(m)*8:return -2
 for i in 0..<int(m):
  var z:float64
  if op==0:
   let x=float64(v[5+i])/1000.0;let a=float64(l)/1000.0;let b=float64(p)/1000.0;let c=float64(r)/1000.0
   let u=if b>a:(x-a)/(b-a) elif x<b:0.0 else:1.0
   let w=if c>b:(c-x)/(c-b) elif x>c:0.0 else:1.0
   z=max(0.0,min(1.0,min(u,w)))
  else:
   let a=float64(v[5+int(m)+i])/1000.0;let b=float64(v[5+2*int(m)+i])/1000.0
   case op
   of 1:z=max(a,b)
   of 2:z=min(a,b)
   of 3:z=1.0-a
   of 4:z=min(a,1.0-b)
   of 5:z=a+b-a*b
   of 6:z=a*b
   of 7:z=min(1.0,a+b)
   else:z=max(0.0,a+b-1.0)
  putd(o,i*8,z)
 int64(m*8)
