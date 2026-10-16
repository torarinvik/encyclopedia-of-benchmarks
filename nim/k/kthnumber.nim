proc partition(a:var array[16,int64],lo,hi:int64):int64=
 let pivot=a[hi];var i=lo
 for j in lo..<hi:
  if a[j]<pivot:swap(a[i],a[j]);inc i
 swap(a[i],a[hi]);i
proc kthnumber*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kthnumber".}=
 if n<4 or n>19:return -1
 let count=v[0];let mode=v[1];let k=v[2]
 if count<1 or count>16 or n!=count+3 or (mode!=1 and mode!=2) or k<1 or k>count:return -1
 var a:array[16,int64]
 for i in 0..<count:
  a[i]=v[i+3]
  if a[i]<-10000 or a[i]>10000:return -1
 var target=k-1
 if mode==2:target=count-k
 var lo:int64=0;var hi=count-1
 while lo<=hi:
  let q=partition(a,lo,hi)
  if q==target:return a[q]
  if q<target:lo=q+1 else:hi=q-1
 -1
