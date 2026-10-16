proc length_of_list*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"length_of_list".}=
 if n>64:return -1
 for i in 0..<n:if v[i]<0 or v[i]>100000:return -1
 int64(n)
