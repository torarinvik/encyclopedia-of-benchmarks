proc log_two*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"log_two".}=
 if v.isNil or n!=1 or v[0]<0 or v[0]>2147483647:return -1
 var x=v[0];var r=0'i64
 while (x shr 1)!=0:x=x shr 1;inc r
 r
