const MaxText=4096
proc prefix_function*(v:ptr UncheckedArray[int64],n:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"prefix_function".}=
 if v.isNil or n<1 or n>MaxText+1 or v[0]<0 or v[0]>MaxText or n!=csize_t(v[0]+1):return -1
 let length=int(v[0]);for i in 0..<length:
  if v[i+1]<0 or v[i+1]>127:return -1
 let bytes=4*length;if bytes>int(cap) or (bytes>0 and out.isNil):return -2
 var pi:array[MaxText,int]
 for i in 1..<length:
  var j=pi[i-1]
  while j>0 and v[i+1]!=v[j+1]:j=pi[j-1]
  if v[i+1]==v[j+1]:inc j
  pi[i]=j
 for i in 0..<length:
  let x=uint32(pi[i]);for k in 0..3:out[4*i+k]=uint8((x shr (8*k)) and 255)
 int64(bytes)
