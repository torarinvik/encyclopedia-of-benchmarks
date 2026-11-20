## Independently authored bounded subset-assignment draft; unverified.
proc tree_sibling_distinct_cost_coloring*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tree_sibling_distinct_cost_coloring".} =
  if input == nil or length < 3 or length > 354: return -1
  if input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > 10: return -1
  let n = int(input[0])
  let k = int(input[1])
  if length != csize_t(n+1+n*k): return -1
  for vertex in 1 ..< n:
    if input[1+vertex] < 0 or input[1+vertex] >= int64(vertex): return -1
  for i in 0 ..< n*k:
    if input[n+1+i] < 0 or input[n+1+i] > 1_000_000: return -1
  const inf = 1_000_000_000_000'i64
  let states = 1 shl k
  var dp: array[32, array[10, int64]]
  var current, next: array[1024, int64]
  var vertex = n
  while vertex > 0:
    dec vertex
    for color in 0 ..< k:
      for mask in 0 ..< states: current[mask] = inf
      current[1 shl color] = 0
      for child in vertex+1 ..< n:
        if input[1+child] != int64(vertex): continue
        for mask in 0 ..< states: next[mask] = inf
        for mask in 0 ..< states:
          if current[mask] == inf: continue
          for c in 0 ..< k:
            let bit = 1 shl c
            if (mask and bit) != 0 or dp[child][c] == inf: continue
            let target = mask or bit
            next[target] = min(next[target], current[mask]+dp[child][c])
        for mask in 0 ..< states: current[mask] = next[mask]
      var best = inf
      for mask in 0 ..< states: best = min(best, current[mask])
      dp[vertex][color] = if best == inf: inf else: best + input[n+1+vertex*k+color]
  var best = inf
  for color in 0 ..< k: best = min(best, dp[0][color])
  return (if best == inf: -2 else: best)
