proc solve(a:openArray[int64],out:var array[10,int64]):int=
 if a.len<=1:
  if a.len==1:out[0]=a[0]
  return a.len
 let pivot=a[0]
 var best,sub,cand:array[10,int64]
 var bl=0
 var i=1
 while i<a.len:
  if a[i]<pivot:
   var tail:seq[int64]=@[]
   for j in i+1..<a.len:
    if a[j]>=a[i]:tail.add(a[j])
   var co:array[10,int64]
   let sl=solve(tail,co)
   cand[0]=a[i]
   for q in 0..<sl:cand[q+1]=co[q]
   if sl+1>bl:
    bl=sl+1;best[0]=cand[0];i=1
    while i<bl:best[i]=cand[i];inc i
  inc i
 var tail:seq[int64]=@[]
 for i in 1..<a.len:
  if a[i]>=pivot:tail.add(a[i])
 var co:array[10,int64]
 let sl=solve(tail,co);cand[0]=pivot
 for q in 0..<sl:cand[q+1]=co[q]
 if sl+1>bl:bl=sl+1;for q in 0..<bl:best[q]=cand[q]
 for q in 0..<bl:out[q]=best[q]
 bl
proc longest_subsequence*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"longest_subsequence".}=
 if n<2 or n>11:return -1
 let k=v[0]
 if k<1 or k>10 or n!=k+1:return -1
 var a:array[10,int64]
 for i in 0..<k:
  a[i]=v[i+1]
  if a[i]<-10 or a[i]>10:return -1
 var out:array[10,int64]
 let length=solve(a.toOpenArray(0,int(k)-1),out)
 var r=int64(length)
 for i in 0..<length:r=r*21+out[i]+10
 r
