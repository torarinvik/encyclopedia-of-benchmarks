proc undirected_cycle_check_bfs*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "undirected_cycle_check_bfs".} =
  if input == nil or length < 2 or length > 514: return -1
  if input[0] < 0 or input[0] > 32 or input[1] < 0 or input[1] > 256: return -1
  let n = int(input[0]); let m = int(input[1])
  if length != csize_t(2 + 2 * m): return -1
  var adjacent: array[32, array[32, bool]]
  var visited: array[32, bool]
  for i in 0 ..< m:
    let a = input[2 + 2 * i]; let b = input[3 + 2 * i]
    if a < 0 or b < 0 or a >= int64(n) or b >= int64(n): return -1
    let u = int(a); let v = int(b)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true; adjacent[v][u] = true
  var queue, parent: array[32, int]
  for root in 0 ..< n:
    if visited[root]: continue
    var head = 0; var tail = 1
    queue[0] = root; parent[root] = n; visited[root] = true
    while head < tail:
      let u = queue[head]; inc head
      for v in 0 ..< n:
        if adjacent[u][v]:
          if not visited[v]:
            visited[v] = true; parent[v] = u; queue[tail] = v; inc tail
          elif v != parent[u]: return 1
  return 0
