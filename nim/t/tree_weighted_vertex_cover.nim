## Uncompiled weighted tree vertex-cover draft.
proc tree_weighted_vertex_cover*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_weighted_vertex_cover".} =
  if input == nil or length < 2 or length > 129: return -1
  let nv=input[0]
  if nv<1 or nv>64 or length!=csize_t(2*nv): return -1
  let n=int(nv)
  for v in 1 ..< n:
    if input[v]<0 or input[v]>=int64(v): return -1
  var included, excluded: array[64, int64]
  for v in 0 ..< n:
    let weight=input[n+v]
    if weight<0 or weight>1_000_000: return -1
    included[v]=weight
  var v=n-1
  while v>0:
    let parent=int(input[v])
    included[parent]+=min(included[v],excluded[v])
    excluded[parent]+=included[v]
    dec v
  min(included[0],excluded[0])
