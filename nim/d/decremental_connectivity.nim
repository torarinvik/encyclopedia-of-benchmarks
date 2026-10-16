const MaxN=32
const MaxQ=128
proc dcFind(parent: var array[MaxN,int], x0: int): int =
  var x=x0
  while parent[x]!=x: parent[x]=parent[parent[x]];x=parent[x]
  x
proc dcSide(adj: array[MaxN,uint64], n,start: int, output_nodes: var array[MaxN,int]): int =
  var seen: array[MaxN,bool];var stack: array[MaxN,int];var top=0;result=0;stack[top]=start;top+=1
  while top>0:
    top-=1;let u=stack[top]
    if seen[u]:continue
    seen[u]=true;output_nodes[result]=u;result+=1
    for v in 0..<n:
      if ((adj[u] shr v) and 1)!=0 and not seen[v]:stack[top]=v;top+=1
proc decremental_connectivity*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl,exportc:"decremental_connectivity".} =
  if a.isNil or length<3 or length>449:return -1
  let n64=a[0];let m64=a[1]
  if n64<1 or n64>MaxN or m64<0 or m64>=n64:return -1
  let n=int(n64);let m=int(m64);let ep=2+2*m
  if length<=csize_t(ep):return -1
  let q64=a[ep]
  if q64<0 or q64>MaxQ or length!=csize_t(ep+1+3*int(q64)):return -1
  let q=int(q64)
  var adj: array[MaxN,uint64];var parent: array[MaxN,int]
  for i in 0..<n:parent[i]=i
  for i in 0..<m:
    let u64=a[2+2*i];let v64=a[3+2*i]
    if u64<0 or u64>=n64 or v64<0 or v64>=n64 or u64==v64:return -1
    let u=int(u64);let v=int(v64)
    if ((adj[u] shr v) and 1)!=0:return -1
    let ru=dcFind(parent,u);let rv=dcFind(parent,v)
    if ru==rv:return -1
    parent[rv]=ru;adj[u]=adj[u] or (1'u64 shl v);adj[v]=adj[v] or (1'u64 shl u)
  var comp: array[MaxN,int];for i in 0..<n:comp[i] = -1
  var next=0;var stack: array[MaxN,int]
  for start in 0..<n:
    if comp[start]>=0:continue
    var top=0;stack[top]=start;top+=1;comp[start]=next
    while top>0:
      top-=1;let u=stack[top]
      for v in 0..<n:
        if ((adj[u] shr v) and 1)!=0 and comp[v]<0:comp[v]=next;stack[top]=v;top+=1
    next+=1
  var h=14695981039346656037'u64
  for k in 0..<q:
    let p=ep+1+3*k;let op=a[p];let u64=a[p+1];let v64=a[p+2]
    if (op!=0 and op!=1) or u64<0 or u64>=n64 or v64<0 or v64>=n64:return -1
    let u=int(u64);let v=int(v64)
    if op==1:h=(h xor uint64(comp[u]==comp[v]))*1099511628211'u64;continue
    if ((adj[u] shr v) and 1)==0 or comp[u]!=comp[v]:return -1
    adj[u]=adj[u] and not (1'u64 shl v);adj[v]=adj[v] and not (1'u64 shl u)
    var left,right: array[MaxN,int];let lc=dcSide(adj,n,u,left);let rc=dcSide(adj,n,v,right)
    if lc<rc or (lc==rc and u<v):
      for j in 0..<lc:comp[left[j]]=next
    else:
      for j in 0..<rc:comp[right[j]]=next
    next+=1
  cast[int64](h)
