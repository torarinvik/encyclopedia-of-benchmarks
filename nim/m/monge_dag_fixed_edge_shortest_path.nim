const MaxN = 32
const Side = 33
const MaxInput = 531
const Inf = 1152921504606846976'i64

proc mongeDagFixedEdgeShortestPath*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "monge_dag_fixed_edge_shortest_path".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let dValue = input[1]
  if nValue < 1 or nValue > MaxN or dValue < 1 or dValue > nValue: return -1
  let n = int(nValue)
  let layers = int(dValue)
  if int(length) != 2 + n * (n + 1) div 2: return -1

  var cost: array[1089, int64]
  var offset = 2
  for u in 0 ..< n:
    for v in u + 1 .. n:
      let weight = input[offset]
      inc offset
      if weight < 0 or weight > 1_000_000: return -1
      cost[u * Side + v] = weight
  for u in 0 ..< max(0, n - 1):
    for v in u + 2 ..< n:
      if cost[u * Side + v] + cost[(u + 1) * Side + v + 1] >
          cost[u * Side + v + 1] + cost[(u + 1) * Side + v]: return -1

  var dp: array[33, int64]
  var next: array[33, int64]
  for v in 0 .. n: dp[v] = Inf
  dp[0] = 0
  for layer in 1 .. layers:
    for v in 0 .. n: next[v] = Inf
    var rowBegin, rowEnd, colBegin, colEnd: array[64, int]
    var top = 1
    rowBegin[0] = layer; rowEnd[0] = n + 1
    colBegin[0] = layer - 1; colEnd[0] = n
    while top > 0:
      dec top
      let rb = rowBegin[top]; let re = rowEnd[top]
      let cb = colBegin[top]; let ce = colEnd[top]
      if rb >= re: continue
      let row = (rb + re) div 2
      let upper = min(ce, row)
      var bestColumn = cb
      var bestValue = Inf
      for column in cb ..< upper:
        if dp[column] == Inf: continue
        let candidate = dp[column] + cost[column * Side + row]
        if candidate < bestValue:
          bestValue = candidate
          bestColumn = column
      next[row] = bestValue
      if row + 1 < re and bestColumn < ce:
        rowBegin[top] = row + 1; rowEnd[top] = re
        colBegin[top] = bestColumn; colEnd[top] = ce
        inc top
      if rb < row and cb <= bestColumn:
        rowBegin[top] = rb; rowEnd[top] = row
        colBegin[top] = cb; colEnd[top] = bestColumn + 1
        inc top
    dp = next
  dp[n]
