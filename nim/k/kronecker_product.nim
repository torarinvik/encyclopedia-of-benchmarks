proc kronecker_product*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kronecker_product".}=
 if n!=6:return -1
 for i in 0..<6:
  if v[i] < -10 or v[i]>10:return -1
 let x=[v[0]*v[4],v[0]*v[5],v[1]*v[4],v[1]*v[5],v[2]*v[4],v[2]*v[5],v[3]*v[4],v[3]*v[5]]
 var r:int64=0
 for z in x:r=r*201+z+100
 r
