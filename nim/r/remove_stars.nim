const MaxInputLength=4096
proc remove_stars*(v:ptr UncheckedArray[int64],n:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"remove_stars".}=
 if v.isNil or n<1 or n>MaxInputLength+1 or v[0]<0 or v[0]>MaxInputLength or n!=csize_t(v[0]+1):return -1
 var result=0
 for i in 0..<int(v[0]):
  if v[i+1]<0 or v[i+1]>127:return -1
  if v[i+1]==42: if result>0:dec result
  else: inc result
 if result>int(cap) or (result>0 and out.isNil):return -2
 var w=0
 for i in 0..<int(v[0]):
  if v[i+1]==42: if w>0:dec w
  else: out[w]=uint8(v[i+1]);inc w
 int64(w)
