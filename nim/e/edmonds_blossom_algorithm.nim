const MaxV = 20

proc edmonds_blossom_algorithm*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "edmonds_blossom_algorithm".} =
  if input.isNil or length < 2: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 0 or n64 > MaxV or m64 < 0 or m64 > 190 or length != csize_t(2 + 2 * m64): return -1
  let n = int(n64)
  var graph: array[MaxV * MaxV, bool]
  for i in 0 ..< int(m64):
    let a = input[2 + 2 * i]
    let b = input[3 + 2 * i]
    if a < 0 or b < 0 or a >= n64 or b >= n64 or a == b: return -1
    let u = int(a); let v = int(b)
    graph[u * MaxV + v] = true
    graph[v * MaxV + u] = true
  var mate, parent, base, queue: array[MaxV, int]
  var used, blossom: array[MaxV, bool]
  for i in 0 ..< n: mate[i] = -1
  var matching = 0
  for root in 0 ..< n:
    if mate[root] != -1: continue
    for i in 0 ..< n:
      used[i] = false; parent[i] = -1; base[i] = i
    var head = 0; var tail = 0
    queue[tail] = root; inc tail; used[root] = true
    var endpoint = -1
    while head < tail and endpoint == -1:
      let v = queue[head]; inc head
      for u in 0 ..< n:
        if not graph[v * MaxV + u] or base[v] == base[u] or mate[v] == u: continue
        if u == root or (mate[u] != -1 and parent[mate[u]] != -1):
          var mark: array[MaxV, bool]
          var x = v; var y = u
          while true:
            x = base[x]; mark[x] = true
            if mate[x] == -1: break
            x = parent[mate[x]]
          while not mark[base[y]]: y = parent[mate[base[y]]]
          let common = base[y]
          for i in 0 ..< n: blossom[i] = false
          x = v; y = u
          while base[x] != common:
            blossom[base[x]] = true; blossom[base[mate[x]]] = true
            parent[x] = y; y = mate[x]; x = parent[mate[x]]
          x = u; y = v
          while base[x] != common:
            blossom[base[x]] = true; blossom[base[mate[x]]] = true
            parent[x] = y; y = mate[x]; x = parent[mate[x]]
          for i in 0 ..< n:
            if blossom[base[i]]:
              base[i] = common
              if not used[i]: used[i] = true; queue[tail] = i; inc tail
        elif parent[u] == -1:
          parent[u] = v
          if mate[u] == -1: endpoint = u; break
          let next = mate[u]
          used[next] = true; queue[tail] = next; inc tail
    if endpoint != -1:
      inc matching
      var v = endpoint
      while v != -1:
        let pv = parent[v]
        let next = if pv == -1: -1 else: mate[pv]
        mate[v] = pv
        if pv != -1: mate[pv] = v
        v = next
  int64(matching)
