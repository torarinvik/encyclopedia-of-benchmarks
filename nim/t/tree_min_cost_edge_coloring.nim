## Uncompiled matching-sensitivity tree edge-coloring draft.
const inf = 1_000_000_000_000_000'i64
type CostMatrix = array[16, array[16, int64]]

proc assignment(d, width: int, cost: CostMatrix, deletion: var array[16, int64]): int64 =
  var rowDual, colDual: array[17, int64]
  var owner: array[17, int]
  for row in 1 .. d:
    var previous: array[17, int]
    var used: array[17, bool]
    var slack: array[17, int64]
    for col in 0 .. width: slack[col] = inf
    owner[0] = row
    var col = 0
    while true:
      used[col] = true
      let active = owner[col]
      var step = inf
      var nextCol = 0
      for candidate in 1 .. width:
        if not used[candidate]:
          let reduced = cost[active-1][candidate-1] - rowDual[active] - colDual[candidate]
          if reduced < slack[candidate]:
            slack[candidate] = reduced
            previous[candidate] = col
          if slack[candidate] < step:
            step = slack[candidate]
            nextCol = candidate
      if nextCol == 0: return -1
      for candidate in 0 .. width:
        if used[candidate]:
          rowDual[owner[candidate]] += step
          colDual[candidate] -= step
        elif candidate != 0: slack[candidate] -= step
      col = nextCol
      if owner[col] == 0: break
    while col != 0:
      let parent = previous[col]
      owner[col] = owner[parent]
      col = parent
  var base = 0'i64
  var freeCol = -1
  for col in 0 ..< width:
    if owner[col+1] != 0: base += cost[owner[col+1]-1][col]
    else: freeCol = col
  if width == d: return base
  if freeCol < 0: return -1
  var distance: array[16, int64]
  for col in 0 ..< width: distance[col] = inf
  distance[freeCol] = 0
  for pass in 0 ..< d:
    var updated = distance
    for col in 0 ..< width:
      let row = owner[col+1]-1
      if row < 0: continue
      for dest in 0 ..< width:
        if distance[dest] != inf:
          updated[col] = min(updated[col], cost[row][dest]-cost[row][col]+distance[dest])
    distance = updated
  for col in 0 ..< width:
    if distance[col] == inf: return -1
    deletion[col] = base + distance[col]
  base

proc tree_min_cost_edge_coloring*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_min_cost_edge_coloring".} =
  if input == nil or length < 2 or length > 82: return -1
  let nv = input[0]
  let kv = input[1]
  if nv < 1 or nv > 64 or kv < 1 or kv > 16: return -1
  let n = int(nv)
  let k = int(kv)
  if length != csize_t(n+1+k): return -1
  var parents, degree, childCount: array[64, int]
  for vertex in 1 ..< n:
    let parent = input[1+vertex]
    if parent < 0 or parent >= int64(vertex): return -1
    parents[vertex] = int(parent)
    inc degree[int(parent)]
    inc degree[vertex]
  var prices: array[16, int64]
  for color in 0 ..< k:
    let value = input[n+1+color]
    if value < 0 or value > 1_000_000: return -1
    prices[color] = value
  for vertex in 0 ..< n:
    if degree[vertex] > k: return -2
  for color in 1 ..< k:
    let value = prices[color]
    var j = color
    while j > 0 and prices[j-1] > value:
      prices[j] = prices[j-1]
      dec j
    prices[j] = value
  var children: array[64, array[16, int]]
  for vertex in 1 ..< n:
    let parent = parents[vertex]
    children[parent][childCount[parent]] = vertex
    inc childCount[parent]
  var tables: array[64, array[16, int64]]
  var vertex = n-1
  while vertex >= 0:
    let d = childCount[vertex]
    if d != 0:
      let saturated = vertex == 0 and d == k
      let width = if saturated: d else: d+1
      var cost: CostMatrix
      var deletion: array[16, int64]
      for row in 0 ..< d:
        let child = children[vertex][row]
        for col in 0 ..< width:
          cost[row][col] = prices[col] + tables[child][min(col, childCount[child])]
      let base = assignment(d, width, cost, deletion)
      if base < 0: return -1
      if saturated: tables[vertex][0] = base
      else:
        for col in 0 ..< width: tables[vertex][col] = deletion[col]
    dec vertex
  if childCount[0] == k: tables[0][0] else: tables[0][childCount[0]]
