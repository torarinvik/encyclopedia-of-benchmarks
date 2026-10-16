proc core(a0,b0:int64):int64=
 if b0==0:return 0
 let neg=(a0<0) xor (b0<0)
 var a=abs(a0);let b=abs(b0);var ds:array[16,int64];var n=0
 if a==0:n=1
 while a>0:ds[n]=a mod 10;a=a div 10;inc n
 var rem=0'i64;var q=0'i64
 while n>0:
  dec n;rem=rem*10+ds[n];var d=0'i64
  while rem>=b:rem-=b;inc d
  q=q*10+d
 if neg:-q else:q
proc long_division*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"long_division".}=
 if v.isNil or n!=2 or v[0]< -1000000 or v[0]>1000000 or v[1]< -10000 or v[1]>10000:return -1
 core(v[0],v[1])
