proc kth_element_in_a_list*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kth_element_in_a_list".}=
 if n<3 or n>34:return -1
 let k=v[0];let pos=v[1]
 if k<1 or k>16 or n!=k+2 or pos<1 or pos>k:return -1
 for i in 0..<k:
  if v[i+2] < -10000 or v[i+2]>10000:return -1
 v[pos+1]
