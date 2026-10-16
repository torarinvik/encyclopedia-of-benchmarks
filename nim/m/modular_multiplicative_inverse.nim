proc modular_multiplicative_inverse*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"modular_multiplicative_inverse".}=
 if v.isNil or n!=2:return -1
 let a=v[0];let m=v[1];if m<2 or m>1_000_000 or a<0 or a>=m:return -1
 var r0=a;var r1=m;var s0=1'i64;var s1=0'i64
 while r1!=0:
  let q=r0 div r1;let t=r0-q*r1;r0=r1;r1=t
  let u=s0-q*s1;s0=s1;s1=u
 if r0==1:(s0 mod m + m) mod m else:-1
