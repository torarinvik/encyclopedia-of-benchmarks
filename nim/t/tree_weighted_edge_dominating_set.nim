## Uncompiled minimum-weight tree edge-domination draft.
proc tree_weighted_edge_dominating_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_weighted_edge_dominating_set".} =
  if input == nil or length < 1 or length > 128: return -1
  let nv = input[0]
  if nv < 1 or nv > 64 or length != csize_t(2*nv-1): return -1
  let n = int(nv)
  for v in 1 ..< n:
    if input[v] < 0 or input[v] >= int64(v) or input[n+v-1] < 0 or input[n+v-1] > 1_000_000: return -1
  const inf = 1_000_000_000_000'i64
  var selected, closed, pending: array[64, int64]
  for v in 0 ..< n: selected[v] = inf
  var v = n-1
  while v > 0:
    let p = int(input[v])
    let skip = min(selected[v], closed[v])
    let take = input[n+v-1] + min(selected[v], pending[v])
    selected[p] = min(inf, min(selected[p] + min(skip, take), pending[p] + take))
    closed[p] = min(inf, closed[p] + selected[v])
    pending[p] = min(inf, pending[p] + skip)
    dec v
  min(selected[0], closed[0])
