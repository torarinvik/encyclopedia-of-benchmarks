proc last_item_in_a_list*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"last_item_in_a_list".}=
 if n>64:return -1
 for i in 0..<n:if v[i]<0 or v[i]>100000:return -1
 if n==0:return -1
 v[n-1]
