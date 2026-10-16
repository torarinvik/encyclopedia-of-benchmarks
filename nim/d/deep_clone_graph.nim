const MaxN=16
proc mix(h0,x0:uint64):uint64 =
  var h=h0;var x=x0
  for b in 0..<8: h=(h xor (x and 255'u64))*1099511628211'u64;x=x shr 8
  h
proc deep_clone_graph*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl,exportc:"deep_clone_graph".} =
  if a.isNil or length<4 or length>34:return -1
  let n64=a[0];let root64=a[1]
  if n64<1 or n64>MaxN or root64<0 or root64>=n64 or length!=csize_t(2+2*n64):return -1
  let n=int(n64);let root=int(root64)
  var labels:array[MaxN,int64];var masks:array[MaxN,uint64];var clones:array[MaxN,uint64];var seen:array[MaxN,bool]
  var stack:array[256,int];var top=0;var count=0
  for i in 0..<n:
    if a[2+i]< -2147483648'i64 or a[2+i]>2147483647'i64 or a[2+n+i]<0 or (uint64(a[2+n+i]) shr n)!=0:return -1
    labels[i]=a[2+i];masks[i]=uint64(a[2+n+i])
  for i in 0..<n:
    for j in 0..<n:
      if ((masks[i] shr j) and 1)!=((masks[j] shr i) and 1):return -1
  stack[top]=root;top+=1
  while top>0:
    top-=1;let u=stack[top]
    if seen[u]:continue
    seen[u]=true;count+=1;clones[u]=masks[u]
    for v in 0..<n:
      if ((masks[u] shr v) and 1)!=0 and not seen[v]:stack[top]=v;top+=1
  var h=mix(14695981039346656037'u64,uint64(count));h=mix(h,uint64(root))
  for i in 0..<n:
    if seen[i]:h=mix(h,cast[uint64](labels[i]));h=mix(h,clones[i])
  cast[int64](h)
