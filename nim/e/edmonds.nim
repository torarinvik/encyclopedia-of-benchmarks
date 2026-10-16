const NMax = 5
const EMax = 12
const Inf = 1_000_000_000'i64
type Edge = object
  u, v: int
  w: int64
proc edmonds*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "edmonds".} =
  if a.isNil or length < 3 or length > 39: return -1
  let n0=a[0]; let r0=a[1]; let m0=a[2]
  if n0<1 or n0>NMax or r0<0 or r0>=n0 or m0<0 or m0>EMax or length != csize_t(3+3*m0): return -1
  var n=int(n0); var root=int(r0); let m=int(m0)
  var edges: array[EMax, Edge]
  for i in 0..<m:
    let u=a[3+3*i]; let v=a[4+3*i]; let w=a[5+3*i]
    if u<0 or u>=n0 or v<0 or v>=n0 or w<0 or w>100: return -1
    edges[i]=Edge(u:int(u),v:int(v),w:w)
  var answer=0'i64
  while true:
    var inn: array[NMax,int64]; var pre: array[NMax,int]
    for i in 0..<n: inn[i]=Inf; pre[i]= -1
    for i in 0..<m:
      let e=edges[i]
      if e.u!=e.v and e.v!=root and e.w<inn[e.v]: inn[e.v]=e.w; pre[e.v]=e.u
    inn[root]=0
    for i in 0..<n:
      if inn[i]==Inf: return -1
    var ids: array[NMax,int]; var vis: array[NMax,int]
    for i in 0..<n: ids[i]= -1; vis[i]= -1
    var cycles=0
    for i in 0..<n:
      answer+=inn[i]
      var v=i
      while vis[v]!=i and ids[v]== -1 and v!=root:
        vis[v]=i; v=pre[v]
      if v!=root and ids[v]== -1:
        var u=pre[v]
        while u!=v: ids[u]=cycles; u=pre[u]
        ids[v]=cycles; inc cycles
    if cycles==0: return answer
    for i in 0..<n:
      if ids[i]== -1: ids[i]=cycles; inc cycles
    var next: array[EMax,Edge]
    for i in 0..<m:
      let e=edges[i]; let u=ids[e.u]; let v=ids[e.v]; var w=e.w
      if u!=v: w-=inn[e.v]
      next[i]=Edge(u:u,v:v,w:w)
    root=ids[root]; n=cycles; edges=next
