const MaxN=16
const MaxM=24
const MaxInput=74

proc randomized_contraction_edge_sampling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"randomized_contraction_edge_sampling".} =
  if input.isNil or length<csize_t(5) or length>csize_t(MaxInput): return -1
  let n64=input[0];let m64=input[1]
  if n64<2 or n64>MaxN or m64<n64-1 or m64>MaxM or int64(length)!=2+3*m64: return -1
  let n=int(n64);let m=int(m64)
  var eu,ev,bits: array[MaxM,int64]
  for i in 0..<m:
    eu[i]=input[2+3*i];ev[i]=input[3+3*i];bits[i]=input[4+3*i]
    if eu[i]<0 or eu[i]>=ev[i] or ev[i]>=n64 or (bits[i]!=0 and bits[i]!=1): return -1
    for j in 0..<i:
      if eu[i]==eu[j] and ev[i]==ev[j]: return -1
  var seen: array[MaxN,bool]
  var queue: array[MaxN,int]
  var head=0;var tail=1;queue[0]=0;seen[0]=true
  while head<tail:
    let current=queue[head];inc head
    for e in 0..<m:
      var next = -1
      if int(eu[e])==current: next=int(ev[e])
      elif int(ev[e])==current: next=int(eu[e])
      if next>=0 and not seen[next]: seen[next]=true;queue[tail]=next;inc tail
  if tail!=n: return -1
  var parent: array[MaxN,int]
  for i in 0..<n: parent[i]=i
  for e in 0..<m:
    if bits[e]!=0:
      var a=int(eu[e]);var b=int(ev[e])
      while parent[a]!=a: a=parent[a]
      while parent[b]!=b: b=parent[b]
      if a!=b: parent[b]=a
  var minimum: array[MaxN,int]
  for i in 0..<n: minimum[i]=n
  for vertex in 0..<n:
    var root=vertex
    while parent[root]!=root: root=parent[root]
    minimum[root]=min(minimum[root],vertex)
  let bytes=4*n
  if output.isNil or capacity<csize_t(bytes): return -2
  var staged: array[4*MaxN,uint8]
  for vertex in 0..<n:
    var root=vertex
    while parent[root]!=root: root=parent[root]
    let bits=uint32(minimum[root])
    for j in 0..<4: staged[4*vertex+j]=uint8((bits shr (8*j)) and 255)
  for i in 0..<bytes: output[i]=staged[i]
  int64(bytes)
