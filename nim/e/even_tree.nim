proc even_tree*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "even_tree".} =
  const invalid = low(int64)
  if values.isNil or length < 2: return invalid
  let nValue = values[0]
  let edgeValue = values[1]
  if nValue < 2 or nValue > 100 or nValue mod 2 != 0 or edgeValue != nValue - 1: return invalid
  let n = int(nValue)
  let edgeCount = int(edgeValue)
  if length != csize_t(2 + 2 * edgeCount): return invalid
  var adjacency: array[100, array[100, bool]]
  for i in 0 ..< edgeCount:
    let uValue = values[2 + 2 * i]
    let vValue = values[3 + 2 * i]
    if uValue < 1 or uValue > nValue or vValue < 1 or vValue > nValue or uValue == vValue: return invalid
    let u = int(uValue - 1)
    let v = int(vValue - 1)
    if adjacency[u][v]: return invalid
    adjacency[u][v] = true
    adjacency[v][u] = true
  var parents: array[100, int]
  var stack: array[100, int]
  var order: array[100, int]
  var subtree: array[100, int64]
  for i in 0 ..< n:
    parents[i] = -2
    subtree[i] = 1
  parents[0] = -1
  var top = 0
  var orderCount = 0
  stack[top] = 0
  inc top
  while top > 0:
    dec top
    let u = stack[top]
    order[orderCount] = u
    inc orderCount
    for v in 0 ..< n:
      if adjacency[u][v] and parents[v] == -2:
        parents[v] = u
        stack[top] = v
        inc top
  if orderCount != n: return invalid
  var cuts = 0'i64
  var index = orderCount
  while index > 0:
    dec index
    let u = order[index]
    if parents[u] >= 0: subtree[parents[u]] += subtree[u]
    if subtree[u] mod 2 == 0: inc cuts
  cuts - 1
