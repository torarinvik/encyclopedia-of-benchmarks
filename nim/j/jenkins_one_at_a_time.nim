proc jenkins_one_at_a_time*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"jenkins_one_at_a_time".}=
 if v.isNil or n<1 or n>65:return -1
 let count=v[0]
 if count<0 or count>64 or n!=csize_t(count+1):return -1
 var h=0'i64
 for i in 0..<int(count):
  let b=v[i+1]
  if b<0 or b>127:return -1
  h=(h+b) and 0xFFFFFFFF'i64
  h=(h+(h shl 10)) and 0xFFFFFFFF'i64
  h=(h xor (h shr 6)) and 0xFFFFFFFF'i64
 h=(h+(h shl 3)) and 0xFFFFFFFF'i64
 h=(h xor (h shr 11)) and 0xFFFFFFFF'i64
 (h+(h shl 15)) and 0xFFFFFFFF'i64
