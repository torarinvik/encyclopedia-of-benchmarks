proc power(a,e,m:int64):int64=
 if e==0:return 1
 if (e mod 2)==1:return (power(a,e-1,m)*a) mod m
 let h=power(a,e div 2,m);(h*h) mod m
proc modular_binary_exponentiation_recursive*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"modular_binary_exponentiation_recursive".}=
 if v.isNil or n!=3:return -1
 let a=v[0];let e=v[1];let m=v[2]
 if a<0 or a>1_000_000 or e<0 or e>60 or m<2 or m>1_000_000:return -1
 power(a,e,m)
