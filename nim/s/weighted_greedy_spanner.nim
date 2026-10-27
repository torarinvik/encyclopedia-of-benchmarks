const MaxN = 8
const MaxM = 28
const MaxInput = 88
const Inf = 1'i64 shl 60

proc weighted_greedy_spanner*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "weighted_greedy_spanner".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let k = input[2]
  if n64 < 2 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or k < 1 or k > 3 or
      int64(length) != 3 + 3 * m64: return -1
  let n = int(n64)
  let m = int(m64)
  var edgeU, edgeV, edgeW: array[MaxM, int64]
  var order: array[MaxM, int]
  var selected: array[MaxM, uint8]
  var adjacency: array[MaxN * MaxN, int64]
  for i in 0..<m:
    edgeU[i] = input[3 + 3 * i]
    edgeV[i] = input[4 + 3 * i]
    edgeW[i] = input[5 + 3 * i]
    if edgeU[i] < 0 or edgeV[i] <= edgeU[i] or edgeV[i] >= n64 or edgeW[i] < 1 or edgeW[i] > 32: return -1
    for j in 0..<i:
      if edgeU[j] == edgeU[i] and edgeV[j] == edgeV[i]: return -1
    order[i] = i
  for i in 1..<m:
    let key = order[i]
    var pos = i
    while pos > 0:
      let prev = order[pos - 1]
      if edgeW[prev] < edgeW[key] or
          (edgeW[prev] == edgeW[key] and edgeU[prev] < edgeU[key]) or
          (edgeW[prev] == edgeW[key] and edgeU[prev] == edgeU[key] and edgeV[prev] <= edgeV[key]): break
      order[pos] = prev
      dec pos
    order[pos] = key
  if output.isNil or capacity < csize_t(m): return -2
  for rank in 0..<m:
    let edge = order[rank]
    let source = int(edgeU[edge])
    let target = int(edgeV[edge])
    var distance: array[MaxN, int64]
    var settled: array[MaxN, bool]
    for v in 0..<n: distance[v] = Inf
    distance[source] = 0
    for _ in 0..<n:
      var vertex = n
      for v in 0..<n:
        if not settled[v] and (vertex == n or distance[v] < distance[vertex]): vertex = v
      if vertex == n or distance[vertex] == Inf: break
      settled[vertex] = true
      for v in 0..<n:
        let weight = adjacency[vertex * MaxN + v]
        if weight > 0 and distance[v] > distance[vertex] + weight:
          distance[v] = distance[vertex] + weight
    if distance[target] > (2 * k - 1) * edgeW[edge]:
      selected[edge] = 1
      adjacency[source * MaxN + target] = edgeW[edge]
      adjacency[target * MaxN + source] = edgeW[edge]
  for i in 0..<m: output[i] = selected[i]
  int64(m)
