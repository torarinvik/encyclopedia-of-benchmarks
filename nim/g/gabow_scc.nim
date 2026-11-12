const MaxN=40
const MaxM=2047
const MaxInput=4096
const MaxOutput=81

proc gabow_scc*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "gabow_scc".} =
  if input.isNil or length<csize_t(2) or length>csize_t(MaxInput): return -1
  if input[0]<0 or input[0]>MaxN or input[1]<0 or input[1]>MaxM: return -1
  let n=int(input[0]); let m=int(input[1])
  if int(length)!=2+2*m: return -1
  var adjacency: array[MaxN,uint64]
  var neighbors: array[MaxN*MaxN,int]
  var degree: array[MaxN,int]
  for e in 0..<m:
    let source=input[2+2*e]; let target=input[3+2*e]
    if source<0 or target<0 or source>=int64(n) or target>=int64(n): return -1
    let u=int(source); let v=int(target); let bit=1'u64 shl v
    if (adjacency[u] and bit)==0:
      adjacency[u] = adjacency[u] or bit
      neighbors[u*MaxN+degree[u]]=v; inc degree[u]
  var preorder: array[MaxN,int64]
  var component: array[MaxN,int64]
  var vertices,boundaries,dfs,nextNeighbor: array[MaxN,int]
  for v in 0..<n: preorder[v]= -1; component[v]= -1
  var vertexCount=0; var boundaryCount=0; var depth=0; var clock=0; var componentCount=0
  for root in 0..<n:
    if preorder[root]>=0: continue
    preorder[root]=int64(clock); inc clock
    vertices[vertexCount]=root; inc vertexCount
    boundaries[boundaryCount]=root; inc boundaryCount
    dfs[depth]=root; nextNeighbor[depth]=0; inc depth
    while depth>0:
      let frame=depth-1; let v=dfs[frame]
      if nextNeighbor[frame]<degree[v]:
        let w=neighbors[v*MaxN+nextNeighbor[frame]]
        inc nextNeighbor[frame]
        if preorder[w]<0:
          preorder[w]=int64(clock); inc clock
          vertices[vertexCount]=w; inc vertexCount
          boundaries[boundaryCount]=w; inc boundaryCount
          dfs[depth]=w; nextNeighbor[depth]=0; inc depth
        elif component[w]<0:
          while boundaryCount>0 and preorder[boundaries[boundaryCount-1]]>preorder[w]: dec boundaryCount
      else:
        dec depth
        if boundaryCount>0 and boundaries[boundaryCount-1]==v:
          dec boundaryCount
          while true:
            dec vertexCount
            let member=vertices[vertexCount]
            component[member]=int64(componentCount)
            if member==v: break
          inc componentCount
  var staged: array[MaxOutput,uint8]
  var position=1
  staged[0]=uint8(componentCount)
  for first in 0..<n:
    let id=component[first]
    var seen=false
    for earlier in 0..<first:
      if component[earlier]==id: seen=true
    if seen: continue
    var size=0
    for v in first..<n:
      if component[v]==id: inc size
    staged[position]=uint8(size); inc position
    for v in first..<n:
      if component[v]==id: staged[position]=uint8(v); inc position
  if output.isNil or outputCapacity<csize_t(position): return -2
  for q in 0..<position: output[q]=staged[q]
  int64(position)
