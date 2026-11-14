proc send(u, sink: int, amount: int64, residual: var array[256, int64],
          level: array[16, int], cursor: var array[16, int], n: int, threshold: int64): int64 =
  if u == sink: return amount
  while cursor[u] < n:
    let v = cursor[u]
    let edge = 16*u+v
    if level[v] == level[u]+1 and residual[edge] >= threshold:
      let pushed = send(v, sink, min(amount, residual[edge]), residual, level, cursor, n, threshold)
      if pushed > 0:
        residual[edge] -= pushed
        residual[16*v+u] += pushed
        return pushed
    inc cursor[u]
  0

proc dinic_capacity_scaling*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dinic_capacity_scaling".} =
  if input.isNil or length < 4 or length > 197: return -1
  let nv=input[0]; let mv=input[1]; let sv=input[2]; let tv=input[3]
  if nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv: return -1
  let n=int(nv); let m=int(mv); let source=int(sv-1); let sink=int(tv-1)
  if length != csize_t(4+3*m): return -1
  var residual: array[256, int64]
  for i in 0 ..< m:
    let u=input[4+3*i]; let v=input[5+3*i]; let capacity=input[6+3*i]
    if u<1 or u>nv or v<1 or v>nv or u==v or capacity<0 or capacity>100: return -1
    residual[16*(int(u)-1)+int(v)-1] += capacity
  var greatest=0'i64
  for i in 0 ..< 256:
    if residual[i]>greatest: greatest=residual[i]
  var threshold=1'i64
  while threshold <= greatest div 2: threshold *= 2
  if greatest==0: threshold=0
  var flow=0'i64
  while threshold>0:
    while true:
      var level: array[16, int]
      for i in 0 ..< 16: level[i] = -1
      var queue: array[16, int]
      var head=0; var tail=1
      level[source]=0; queue[0]=source
      while head<tail:
        let u=queue[head]; inc head
        for v in 0 ..< n:
          if level[v]<0 and residual[16*u+v]>=threshold:
            level[v]=level[u]+1; queue[tail]=v; inc tail
      if level[sink]<0: break
      var cursor: array[16, int]
      while true:
        let pushed=send(source,sink,6401,residual,level,cursor,n,threshold)
        if pushed==0: break
        flow+=pushed
    threshold = threshold div 2
  flow
