proc longestpalindrome*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"longestpalindrome".}=
 if v.isNil or n<1 or n>65:return -1
 let count=v[0]
 if count<0 or count>64 or n!=csize_t(count+1):return -1
 var a:array[64,int64];var m=0
 for i in 0..<int(count):
  let x=v[i+1]
  if x<32 or x>126 or x==35:return -1
  if x!=32:a[m]=x;inc m
 var t:array[129,int64];let z=2*m+1
 for i in 0..<z:if i mod 2==0:t[i]= -1 else:t[i]=a[i div 2]
 var p:array[129,int];var center=0;var right=0;var best=0
 for i in 0..<z:
  if i<right:p[i]=min(p[2*center-i],right-i)
  while i>=p[i]+1 and i+p[i]+1<z and t[i-p[i]-1]==t[i+p[i]+1]:inc p[i]
  best=max(best,p[i]);if i+p[i]>right:center=i;right=i+p[i]
 int64(best)
