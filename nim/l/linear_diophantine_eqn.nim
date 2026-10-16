proc linear_diophantine_eqn*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"linear_diophantine_eqn".}=
 if v.isNil or n!=3:return -1
 let a0=v[0];let b0=v[1];let c=v[2]
 if a0< -100000 or a0>100000 or b0==0 or b0< -100000 or b0>100000 or c< -1000000 or c>1000000:return -1
 var a=abs(a0);var b=abs(b0)
 while b!=0:let r=a mod b;a=b;b=r
 if c mod a==0:1 else:0
