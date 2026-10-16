const MaxText=128
proc minimum_window_substring*(v:ptr UncheckedArray[int64],n:csize_t,out:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"minimum_window_substring".}=
 if v.isNil or n<3 or n>258 or v[0]<0 or v[0]>MaxText:return -1
 let a=int(v[0]);if n<csize_t(a+2):return -1
 let mm=v[a+1];if mm<1 or mm>MaxText:return -1
 let m=int(mm);if n!=csize_t(a+m+2):return -1
 var need:array[128,int]
 for i in 0..<a:
  if v[i+1]<0 or v[i+1]>127:return -1
 for i in 0..<m:
  let c=v[a+2+i];if c<0 or c>127:return -1
  inc need[int(c)]
 var left=0;var best=a+1;var start=0;var missing=m
 for right in 0..<a:
  let c=int(v[right+1]);if need[c]>0:dec missing
  dec need[c]
  while missing==0:
   let length=right-left+1
   if length<best:best=length;start=left
   let x=int(v[left+1]);inc need[x];inc left
   if need[x]>0:inc missing
 if best==a+1:return 0
 if best>int(cap) or (best>0 and out.isNil):return -2
 for i in 0..<best:out[i]=uint8(v[start+1+i])
 int64(best)
