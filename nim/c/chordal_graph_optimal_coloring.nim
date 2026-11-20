## Uncompiled chordal-graph optimal coloring draft.
proc chordal_graph_optimal_coloring*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "chordal_graph_optimal_coloring".} =
  if input == nil or length < 2 or length > 18: return -1
  let nv = input[0]
  if nv < 1 or nv > 16 or length != csize_t(nv+1): return -1
  let n = int(nv)
  var rows, weight, colors, order: array[16, int]
  for v in 0 ..< n:
    if input[v+1] < 0 or input[v+1] >= int64(1 shl n) or (input[v+1] and int64(1 shl v)) != 0: return -1
    rows[v] = int(input[v+1])
    colors[v] = -1
  for v in 0 ..< n:
    for u in 0 ..< v:
      if ((rows[v] shr u) and 1) != ((rows[u] shr v) and 1): return -1
  var selected = 0
  for i in 0 ..< n:
    var v = -1
    for u in 0 ..< n:
      if (selected and (1 shl u)) == 0:
        if v < 0 or weight[u] > weight[v]: v = u
    let earlier = rows[v] and selected
    for j in 0 ..< i:
      let u = order[j]
      if (earlier and (1 shl u)) != 0 and (earlier and not (rows[u] or (1 shl u))) != 0: return -2
    order[i] = v
    selected = selected or (1 shl v)
    for u in 0 ..< n:
      if (selected and (1 shl u)) == 0 and (rows[v] and (1 shl u)) != 0: inc weight[u]
  var maximum = 0
  for i in 0 ..< n:
    let v = order[i]
    var used = 0
    for u in 0 ..< n:
      if (rows[v] and (1 shl u)) != 0 and colors[u] >= 0: used = used or (1 shl colors[u])
    var color = 0
    while (used and (1 shl color)) != 0: inc color
    colors[v] = color
    maximum = max(maximum, color+1)
  int64(maximum)
