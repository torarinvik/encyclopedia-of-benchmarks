proc kth_element_from_end*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kth_element_from_end".}=
 if v.isNil or n<1 or n>65:return -1
 let k=v[0];if k<=0 or k>=int64(n):return -1
 for i in 1..<n:if v[i]<0 or v[i]>100000:return -1
 v[n-csize_t(k)]
