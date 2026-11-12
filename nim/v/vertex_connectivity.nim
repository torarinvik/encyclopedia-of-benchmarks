const MaxN=10
const MaxM=45
const MaxInput=92
const MaxDN=20

proc vertex_connectivity*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "vertex_connectivity".} =
  if input.isNil or length<csize_t(2) or length>csize_t(MaxInput): return -1
  if input[0]<0 or input[0]>MaxN or input[1]<0 or input[1]>MaxM: return -1
  let n=int(input[0]); let m=int(input[1])
  if int(length)!=2+2*m: return -1
  var adjacency: array[MaxN,uint64]
  for e in 0..<m:
    let left=input[2+2*e]; let right=input[3+2*e]
    if left<0 or right<0 or left>=int64(n) or right>=int64(n): return -1
    if left!=right:
      adjacency[int(left)] = adjacency[int(left)] or (1'u64 shl int(right))
      adjacency[int(right)] = adjacency[int(right)] or (1'u64 shl int(left))
  if n<=1: return 0
  var reached=1'u64
  var graphQueue: array[MaxN,int]
  var graphHead=0; var graphTail=0; graphQueue[graphTail]=0; inc graphTail
  while graphHead<graphTail:
    let u=graphQueue[graphHead]; inc graphHead
    for v in 0..<n:
      let bit=1'u64 shl v
      if (adjacency[u] and bit)!=0 and (reached and bit)==0:
        reached = reached or bit; graphQueue[graphTail]=v; inc graphTail
  if reached != ((1'u64 shl n)-1): return 0
  var best=n-1
  for source in 0..<n:
    for target in (source+1)..<n:
      if (adjacency[source] and (1'u64 shl target))!=0: continue
      var residual: array[MaxDN*MaxDN,int]
      let nodes=2*n
      for v in 0..<n:
        residual[(2*v)*MaxDN+(2*v+1)] = if v==source or v==target: n else: 1
      for u in 0..<n:
        for v in (u+1)..<n:
          if (adjacency[u] and (1'u64 shl v))!=0:
            residual[(2*u+1)*MaxDN+2*v]=1
            residual[(2*v+1)*MaxDN+2*u]=1
      let start=2*source+1; let sink=2*target
      var flow=0
      while flow<best:
        var parent: array[MaxDN,int]
        for v in 0..<nodes: parent[v]= -1
        var queue: array[MaxDN,int]
        parent[start]=start; var head=0; var tail=0; queue[tail]=start; inc tail
        while head<tail and parent[sink]<0:
          let u=queue[head]; inc head
          for v in 0..<nodes:
            if parent[v]<0 and residual[u*MaxDN+v]>0:
              parent[v]=u; queue[tail]=v; inc tail
              if v==sink: break
        if parent[sink]<0: break
        var amount=best-flow; var v=sink
        while v!=start:
          let u=parent[v]
          if residual[u*MaxDN+v]<amount: amount=residual[u*MaxDN+v]
          v=u
        v=sink
        while v!=start:
          let u=parent[v]
          residual[u*MaxDN+v]-=amount; residual[v*MaxDN+u]+=amount; v=u
        flow+=amount
      if flow<best: best=flow
      if best==0: return 0
  int64(best)
