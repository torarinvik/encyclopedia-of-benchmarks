const MaxN = 12
const MaxM = 24
const MaxInput = 98

proc kkt_mst_sampling_filter*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"kkt_mst_sampling_filter".} =
  if input.isNil or length < csize_t(6) or length > csize_t(MaxInput): return -1
  let n64=input[0]; let m64=input[1]
  if n64<2 or n64>MaxN or m64<1 or m64>MaxM or int64(length)!=2+4*m64: return -1
  let n=int(n64); let m=int(m64)
  var eu, ev, ew, sample: array[MaxM,int64]
  for i in 0..<m:
    eu[i]=input[2+4*i]; ev[i]=input[3+4*i]; ew[i]=input[4+4*i]; sample[i]=input[5+4*i]
    if eu[i]<0 or eu[i]>=ev[i] or ev[i]>=n64 or ew[i]<1 or ew[i]>1024 or (sample[i]!=0 and sample[i]!=1): return -1
    for j in 0..<i:
      if (eu[i]==eu[j] and ev[i]==ev[j]) or ew[i]==ew[j]: return -1
  if output.isNil or capacity<csize_t(m): return -2
  var order: array[MaxM,int]
  for i in 0..<m: order[i]=i
  for i in 0..<m:
    var best=i
    for j in i+1..<m:
      if ew[order[j]]<ew[order[best]]: best=j
    swap(order[i],order[best])
  var parent: array[MaxN,int]
  for i in 0..<n: parent[i]=i
  var inForest: array[MaxM,bool]
  var staged: array[MaxM,uint8]
  for pos in 0..<m:
    let e=order[pos]
    if sample[e]==0: continue
    var a=int(eu[e]); var b=int(ev[e])
    while parent[a]!=a: a=parent[a]
    while parent[b]!=b: b=parent[b]
    if a!=b: parent[b]=a; inForest[e]=true
  for e in 0..<m:
    if inForest[e]: staged[e]=1; continue
    var pathMax: array[MaxN,int64]
    var queue: array[MaxN,int]
    var seen: array[MaxN,bool]
    for i in 0..<n: pathMax[i] = -1
    let start=int(eu[e]); let target=int(ev[e])
    var head=0; var tail=1
    queue[0]=start; seen[start]=true; pathMax[start]=0
    while head<tail and not seen[target]:
      let current=queue[head]; inc head
      for k in 0..<m:
        if not inForest[k]: continue
        var next = -1
        if int(eu[k])==current: next=int(ev[k])
        elif int(ev[k])==current: next=int(eu[k])
        if next>=0 and not seen[next]:
          seen[next]=true
          pathMax[next]=max(pathMax[current],ew[k])
          queue[tail]=next; inc tail
    staged[e]=uint8(if not seen[target] or ew[e]<pathMax[target]: 1 else: 0)
  for i in 0..<m: output[i]=staged[i]
  int64(m)
