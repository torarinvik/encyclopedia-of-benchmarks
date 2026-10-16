proc iterating_through_submasks*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"iterating_through_submasks".}=
 if v.isNil or n!=1 or v[0]<1 or v[0]>4095:return -1
 let mask=v[0];var submask=mask;var count=0'i64
 while submask!=0:inc count;submask=(submask-1) and mask
 count
