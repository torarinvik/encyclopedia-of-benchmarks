const MaxV = 8
const MaxE = 24
const MaxPaths = 1000
const MaxOutput = 72008

proc putI64(outp: var array[MaxOutput, uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[at+b] = uint8((bits shr (8*b)) and 255)

proc dfs(adj: array[MaxV, array[MaxE, int]], degree: array[MaxV, int], visited: var array[MaxV, bool], path: var array[MaxV, int], depth, target: int, count: var int, outp: var array[MaxOutput, uint8], at: var int, overflow: var bool) =
  if overflow: return
  let u = path[depth-1]
  if u == target:
    if count >= MaxPaths: overflow = true; return
    putI64(outp, at, int64(depth)); at += 8
    for j in 0 ..< depth: putI64(outp, at, int64(path[j])); at += 8
    inc count; return
  visited[u] = true
  for j in 0 ..< degree[u]:
    let next = adj[u][j]
    if not visited[next]:
      path[depth] = next
      dfs(adj, degree, visited, path, depth+1, target, count, outp, at, overflow)
      if overflow: break
  visited[u] = false

proc all_paths_from_source_to_target*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "all_paths_from_source_to_target".} =
  if values == nil or length < 4 or length > 52 or values[0] < 1 or values[0] > MaxV or values[1] < 0 or values[1] > MaxE: return -1
  let nv = int(values[0]); let ne = int(values[1])
  if values[2] < 0 or values[2] >= int64(nv) or values[3] < 0 or values[3] >= int64(nv) or int(length) != 4+2*ne: return -1
  var adj: array[MaxV, array[MaxE, int]]; var degree: array[MaxV, int]
  for e in 0 ..< ne:
    let a=values[4+2*e];let b=values[5+2*e]
    if a<0 or a>=nv or b<0 or b>=nv:return -1
    adj[int(a)][degree[int(a)]]=int(b);inc degree[int(a)]
  var outp: array[MaxOutput, uint8];var path: array[MaxV,int];var visited: array[MaxV,bool]
  var count=0;var at=8;var overflow=false;path[0]=int(values[2])
  dfs(adj,degree,visited,path,1,int(values[3]),count,outp,at,overflow)
  if overflow:return -2
  putI64(outp,0,int64(count))
  if output==nil or int(outputCapacity)<at:return -2
  for i in 0..<at:output[i]=outp[i]
  int64(at)
