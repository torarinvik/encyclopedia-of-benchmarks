## Uncompiled bounded distance-k tree domination draft.
proc tree_distance_k_dominating_set*(input:ptr UncheckedArray[int64],length:csize_t):int64
    {.cdecl,exportc:"tree_distance_k_dominating_set".} =
  if input==nil or length<2 or length>66: return -1
  let nv=input[0]
  let radius=input[1]
  if nv<1 or nv>64 or radius<0 or radius>63 or length!=csize_t(nv+1): return -1
  let n=int(nv)
  var parent,depth,first,next:array[64,int]
  var covered:array[64,bool]
  for v in 0 ..< n: first[v] = -1
  for v in 1 ..< n:
    let raw=input[1+v]
    if raw<0 or raw>=int64(v): return -1
    let p=int(raw)
    parent[v]=p; depth[v]=depth[p]+1
    next[v]=first[p]; first[p]=v
  var answer=0'i64
  while true:
    var deepest = -1
    for v in 0 ..< n:
      if not covered[v] and (deepest<0 or depth[v]>depth[deepest]): deepest=v
    if deepest<0: return answer
    var center=deepest
    var step=0'i64
    while step<radius and center!=0:
      center=parent[center]
      inc step
    var queue,dist:array[64,int]
    for v in 0 ..< n: dist[v] = -1
    var head=0
    var tail=1
    queue[0]=center; dist[center]=0
    while head<tail:
      let v=queue[head]
      inc head
      covered[v]=true
      if int64(dist[v])==radius: continue
      if v!=0 and dist[parent[v]]<0:
        let u=parent[v]
        dist[u]=dist[v]+1; queue[tail]=u; inc tail
      var child=first[v]
      while child>=0:
        if dist[child]<0:
          dist[child]=dist[v]+1; queue[tail]=child; inc tail
        child=next[child]
    inc answer
