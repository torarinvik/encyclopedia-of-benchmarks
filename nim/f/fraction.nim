proc gcdPos(a0,b0:int64):int64=
 var a=abs(a0);var b=abs(b0)
 while b!=0:let r=a mod b;a=b;b=r
 a
proc putI64(o:ptr UncheckedArray[uint8],p:int,x:int64)=
 let bits=cast[uint64](x)
 for k in 0..<8:o[p+k]=uint8((bits shr (8*k)) and 255)
proc fraction*(v:ptr UncheckedArray[int64],n:csize_t,o:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"fraction".}=
 if v==nil or n!=4:return -1
 let n1=v[0];let d1=v[1];let n2=v[2];let d2=v[3]
 if n1 < -10000 or n1>10000 or n2 < -10000 or n2>10000 or d1 < -1000 or d1>1000 or d2 < -1000 or d2>1000 or d1==0 or d2==0:return -1
 if o==nil or cap<16:return -2
 let g=gcdPos(d1,d2);var num=(d2 div g)*n1+(d1 div g)*n2;var den=(d1 div g)*d2
 let r=gcdPos(num,den);num=num div r;den=den div r
 if den<0:num = -num;den = -den
 putI64(o,0,num);putI64(o,8,den);16
