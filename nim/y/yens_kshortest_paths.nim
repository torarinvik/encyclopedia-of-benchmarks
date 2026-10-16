const NMax = 8
const KMax = 8
const CandidateMax = 64

type Path = object
  len: int
  nodes: array[8, int64]
  cost: int64

proc pathLess(a, b: Path): bool =
  if a.cost != b.cost: return a.cost < b.cost
  for i in 0 ..< min(a.len, b.len):
    if a.nodes[i] != b.nodes[i]: return a.nodes[i] < b.nodes[i]
  a.len < b.len

proc samePath(a, b: Path): bool =
  if a.len != b.len: return false
  for i in 0 ..< a.len:
    if a.nodes[i] != b.nodes[i]: return false
  true

proc samePrefix(a, b: Path, n: int): bool =
  if a.len < n or b.len < n: return false
  for i in 0 ..< n:
    if a.nodes[i] != b.nodes[i]: return false
  true

proc contains(path: Path, vertex: int): bool =
  for i in 0 ..< path.len:
    if int(path.nodes[i]) == vertex: return true
  false

proc exploreSpur(graph: var array[64, int64], n, dst: int, bannedVertices: var array[8, bool], bannedEdges: var array[64, bool],
    current: var Path, best: var Path, found: var bool) =
  let u = int(current.nodes[current.len - 1])
  if u == dst:
    if not found or pathLess(current, best): best = current; found = true
    return
  for v in 0 ..< n:
    if graph[u * n + v] < 0 or bannedVertices[v] or bannedEdges[u * NMax + v] or contains(current, v): continue
    current.nodes[current.len] = int64(v)
    current.len += 1
    current.cost += graph[u * n + v]
    exploreSpur(graph, n, dst, bannedVertices, bannedEdges, current, best, found)
    current.cost -= graph[u * n + v]
    current.len -= 1

proc shortest(graph: var array[64, int64], n, src, dst: int, bannedVertices: var array[8, bool], bannedEdges: var array[64, bool], outPath: var Path): bool =
  var current = Path(len: 1, nodes: [int64(src), 0'i64, 0, 0, 0, 0, 0, 0], cost: 0)
  var found = false
  var best: Path
  exploreSpur(graph, n, dst, bannedVertices, bannedEdges, current, best, found)
  if found: outPath = best
  found

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0 ..< 8: output[offset + i] = uint8((bits shr (i * 8)) and 255)

proc yens_kshortest_paths*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], output_capacity: csize_t): int64 {.cdecl, exportc: "yens_kshortest_paths".} =
  if input.isNil or length < 4: return -1
  let nv=input[0]; let kv=input[1]; let sv=input[2]; let dv=input[3]
  if nv < 1 or nv > NMax or kv < 1 or kv > KMax or sv < 0 or sv >= nv or dv < 0 or dv >= nv: return -1
  let n=int(nv); let k=int(kv)
  if length != csize_t(4+n*n): return -1
  var graph: array[64,int64]
  for i in 0 ..< n*n:
    let w=input[4+i]
    if w < -1 or w > 1000: return -1
    graph[i]=w
  var accepted: array[8,Path]
  var candidates: array[CandidateMax,Path]
  var acceptedCount=0; var candidateCount=0
  var bannedVertices: array[8,bool]
  var bannedEdges: array[64,bool]
  var first: Path
  if shortest(graph,n,int(sv),int(dv),bannedVertices,bannedEdges,first): accepted[acceptedCount]=first; acceptedCount+=1
  while acceptedCount<k and acceptedCount>0:
    let previous=accepted[acceptedCount-1]
    for i in 0 ..< previous.len-1:
      var root=Path(len:i+1,nodes:previous.nodes,cost:0)
      for j in 0 ..< i: root.cost+=graph[int(root.nodes[j])*n+int(root.nodes[j+1])]
      for z in 0 ..< acceptedCount:
        if samePrefix(accepted[z],root,i+1) and accepted[z].len>i+1:
          bannedEdges[int(accepted[z].nodes[i])*NMax+int(accepted[z].nodes[i+1])]=true
      for j in 0 ..< i: bannedVertices[int(root.nodes[j])]=true
      var spur: Path
      if shortest(graph,n,int(root.nodes[i]),int(dv),bannedVertices,bannedEdges,spur):
        var total=root
        for j in 1 ..< spur.len: total.nodes[total.len]=spur.nodes[j]; total.len+=1
        total.cost+=spur.cost
        var duplicate=false
        for z in 0 ..< acceptedCount:
          if samePath(total,accepted[z]): duplicate=true
        for z in 0 ..< candidateCount:
          if samePath(total,candidates[z]): duplicate=true
        if not duplicate and candidateCount<CandidateMax: candidates[candidateCount]=total; candidateCount+=1
      for j in 0 ..< i: bannedVertices[int(root.nodes[j])]=false
      for z in 0 ..< acceptedCount:
        if samePrefix(accepted[z],root,i+1) and accepted[z].len>i+1:
          bannedEdges[int(accepted[z].nodes[i])*NMax+int(accepted[z].nodes[i+1])]=false
    if candidateCount==0: break
    var best=0
    for i in 1 ..< candidateCount:
      if pathLess(candidates[i],candidates[best]): best=i
    accepted[acceptedCount]=candidates[best]; acceptedCount+=1
    candidateCount-=1
    if best<candidateCount: candidates[best]=candidates[candidateCount]
  var bytes=8
  for i in 0 ..< acceptedCount: bytes+=(accepted[i].len+2)*8
  if output_capacity<csize_t(bytes):return -2
  if output.isNil:return -2
  putI64(output,0,int64(acceptedCount));var at=8
  for i in 0 ..< acceptedCount:
    putI64(output,at,int64(accepted[i].len));at+=8
    for j in 0 ..< accepted[i].len:putI64(output,at,accepted[i].nodes[j]);at+=8
    putI64(output,at,accepted[i].cost);at+=8
  int64(bytes)
