proc zblock_substring_search*(a:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"zblock_substring_search".}=
 if a==nil or length<3:return -1
 let tn=a[0];let pn=a[1]
 if tn<0 or tn>256 or pn<1 or pn>64 or length!=csize_t(tn+pn+2):return -1
 for i in 2..<int(length):if a[i]<0 or a[i]>127 or a[i]==36:return -1
 let textLen=int(tn);let patLen=int(pn);let n=textLen+patLen+1
 var s:array[321,int64];var z:array[321,int]
 for i in 0..<patLen:s[i]=a[2+tn+i]
 s[patLen] = -1
 for i in 0..<textLen:s[patLen+1+i]=a[2+i]
 var left=0;var right=0
 for i in 1..<n:
  z[i]=if i<=right:min(right-i+1,z[i-left])else:0
  while i+z[i]<n and s[z[i]]==s[i+z[i]]:inc z[i]
  if i+z[i]>0 and i+z[i]-1>right:left=i;right=i+z[i]-1
 var found=0
 for i in patLen+1..<n:if z[i]>=patLen:inc found
 int64(found)
