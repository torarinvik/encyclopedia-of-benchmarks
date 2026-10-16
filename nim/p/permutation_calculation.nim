proc factorial(n:int64):int64=
 var x=1'i64
 for i in 1'i64..n:x*=i
 x
proc permutation_calculation*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"permutation_calculation".}=
 if v.isNil or n!=2 or v[0]<0 or v[0]>15 or v[1]<0 or v[1]>v[0]:return -1
 factorial(v[0]) div factorial(v[0]-v[1])
