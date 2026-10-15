const MaxN = 16
const MaxM = 64

proc dfs(u, sink: int, pushed: int64, residual: var array[MaxN*MaxN,int64], level: var array[MaxN,int], next: var array[MaxN,int], n: int): int64 =
  if u==sink:return pushed
  while next[u]<n:
    let v=next[u];let k=u*MaxN+v
    if level[v]==level[u]+1 and residual[k]>0:
      let sent=dfs(v,sink,min(pushed,residual[k]),residual,level,next,n)
      if sent>0:residual[k]-=sent;residual[v*MaxN+u]+=sent;return sent
    inc next[u]
  return 0

## Return the maximum flow for a bounded directed graph edge list.
proc dinic_maxflow*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "dinic_maxflow".} =
  if input==nil or length<4:return -1
  let nv=input[0];let mv=input[1];let sv=input[2];let tv=input[3]
  if nv<2 or nv>MaxN or mv<0 or mv>MaxM or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv:return -1
  let n=int(nv);let m=int(mv);let s=int(sv-1);let t=int(tv-1)
  if length!=csize_t(4+3*m):return -1
  var residual:array[MaxN*MaxN,int64]
  for i in 0..<m:
    let u=input[4+3*i];let v=input[5+3*i];let c=input[6+3*i]
    if u<1 or u>nv or v<1 or v>nv or u==v or c<0 or c>100:return -1
    residual[(int(u)-1)*MaxN+int(v)-1]+=c
  var flow=0'i64
  while true:
    var level:array[MaxN,int];level.fill(-1)
    var queue:array[MaxN,int];var head=0;var tail=0;level[s]=0;queue[tail]=s;inc tail
    while head<tail:
      let u=queue[head];inc head
      for v in 0..<n:
        if residual[u*MaxN+v]>0 and level[v]<0:level[v]=level[u]+1;queue[tail]=v;inc tail
    if level[t]<0:break
    var next:array[MaxN,int]
    while true:
      let pushed=dfs(s,t,6401,residual,level,next,n)
      if pushed==0:break
      flow+=pushed
  return flow
