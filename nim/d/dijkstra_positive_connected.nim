## Compute source-zero shortest distances in a connected positive graph.
proc putI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8:output[index*8+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc dijkstra_positive_connected*(input: ptr UncheckedArray[int64],length: csize_t,output: ptr UncheckedArray[uint8],capacity: csize_t): int64 {.cdecl,exportc:"dijkstra_positive_connected".}=
  if input.isNil or length<2:return -1
  let nv=input[0];let mv=input[1]
  if nv<1 or nv>4 or mv<0 or mv>6 or length!=csize_t(2+3*mv):return -1
  let n=int(nv);let m=int(mv);if m<n-1 or m>n*(n-1) div 2:return -1
  var weight:array[4,array[4,int64]];var adjacent:array[4,array[4,bool]];var neighbors:array[4,array[6,int]];var degree:array[4,int]
  for e in 0..<m:
    let u=input[2+3*e];let v=input[3+3*e];let w=input[4+3*e]
    if u<0 or u>=nv or v<0 or v>=nv or u==v or w<1 or w>255:return -1
    let a=int(u);let b=int(v);if adjacent[a][b]:return -1
    adjacent[a][b]=true;adjacent[b][a]=true;weight[a][b]=w;weight[b][a]=w
    neighbors[a][degree[a]]=b;inc degree[a];neighbors[b][degree[b]]=a;inc degree[b]
  var seen:array[4,bool];var stack:array[4,int];var top=1;stack[0]=0;seen[0]=true
  while top>0:
    dec top;let u=stack[top]
    for j in 0..<degree[u]:let v=neighbors[u][j];if not seen[v]:seen[v]=true;stack[top]=v;inc top
  for v in 0..<n:if not seen[v]:return -1
  var dist:array[4,int64];var done:array[4,bool]
  for v in 0..<4:dist[v]=high(int64)
  dist[0]=0
  for _ in 0..<n:
    var selected = -1
    for v in 0..<n:if not done[v] and (selected<0 or dist[v]<dist[selected]):selected=v
    if selected<0:break
    done[selected]=true
    for j in 0..<degree[selected]:let v=neighbors[selected][j];if not done[v] and dist[selected]+weight[selected][v]<dist[v]:dist[v]=dist[selected]+weight[selected][v]
  if output.isNil or capacity<csize_t(n*8):return -2
  for v in 0..<n:putI64Le(output,v,dist[v])
  int64(n*8)
