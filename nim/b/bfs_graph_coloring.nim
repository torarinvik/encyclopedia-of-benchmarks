const MaxVertices = 64
const MaxEdges = 2016
const MaxOutputValues = MaxVertices + 2
proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[offset+b] = uint8((bits shr (8*b)) and 255)
proc bfs_graph_coloring*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "bfs_graph_coloring".} =
  if input.isNil or length < 2: return -1
  let nValue=input[0]; let mValue=input[1]
  if nValue < 0 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges: return -1
  let n=int(nValue); let m=int(mValue)
  if int(length) != 2+2*m: return -1
  var adjacency: array[MaxVertices*MaxVertices,bool]
  var degree: array[MaxVertices,int]
  for edge in 0 ..< m:
    let uValue=input[2+2*edge];let vValue=input[3+2*edge]
    if uValue < 0 or uValue >= nValue or vValue < 0 or vValue >= nValue or uValue == vValue: return -1
    let u=int(uValue);let v=int(vValue);let uv=u*MaxVertices+v;let vu=v*MaxVertices+u
    if adjacency[uv]: return -1
    adjacency[uv]=true;adjacency[vu]=true;inc degree[u];inc degree[v]
  var visited: array[MaxVertices,bool]
  var queue: array[MaxVertices,int]
  for start in 0 ..< n:
    if visited[start]: continue
    var head=0;var tail=0;var highDegree=0
    visited[start]=true;queue[tail]=start;inc tail
    while head < tail:
      let vertex=queue[head];inc head
      if degree[vertex] > 1: inc highDegree
      for neighbor in 0 ..< n:
        if adjacency[vertex*MaxVertices+neighbor] and not visited[neighbor]:
          visited[neighbor]=true;queue[tail]=neighbor;inc tail
    if highDegree > 1: return -1
  var colors: array[MaxVertices,int64]
  for vertex in 0 ..< n: colors[vertex]=1
  for vertex in 0 ..< MaxVertices: visited[vertex]=false
  for start in 0 ..< n:
    if visited[start]: continue
    var head=0;var tail=0;visited[start]=true;queue[tail]=start;inc tail
    while head < tail:
      let front=queue[head];inc head
      for neighbor in 0 ..< n:
        if not adjacency[front*MaxVertices+neighbor]: continue
        if colors[neighbor]==colors[front]: inc colors[neighbor]
        if not visited[neighbor]: visited[neighbor]=true;queue[tail]=neighbor;inc tail
  var colorsUsed: int64 = 0
  for vertex in 0 ..< n: colorsUsed=max(colorsUsed,colors[vertex])
  var packed: array[MaxOutputValues,int64]
  packed[0]=nValue
  for vertex in 0 ..< n: packed[vertex+1]=colors[vertex]
  packed[n+1]=colorsUsed
  let used=n+2;let required=used*8
  if output.isNil or int(capacity)<required: return -2
  for i in 0 ..< used: putI64(output,i*8,packed[i])
  int64(required)
