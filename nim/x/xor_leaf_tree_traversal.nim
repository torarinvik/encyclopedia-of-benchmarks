proc xor_leaf_tree_traversal*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "xor_leaf_tree_traversal".} =
  if input.isNil or length < 2 or input[0] < 1 or input[0] > 64: return -1
  let n = int(input[0])
  if input[1] < 0 or input[1] >= int64(n) or int(length) != 2 * n: return -1
  let root = int(input[1])
  var degree, edgeXor, parents, dsu, ranks, order: array[64, int]
  var a, b: array[63, int]
  for i in 0 ..< n:
    parents[i] = -1
    dsu[i] = i
  for e in 0 ..< n - 1:
    let u0 = input[2 + 2 * e]
    let v0 = input[3 + 2 * e]
    if u0 < 0 or u0 >= int64(n) or v0 < 0 or v0 >= int64(n) or u0 == v0: return -1
    let u = int(u0)
    let v = int(v0)
    var x = u
    var y = v
    while dsu[x] != x:
      dsu[x] = dsu[dsu[x]]
      x = dsu[x]
    while dsu[y] != y:
      dsu[y] = dsu[dsu[y]]
      y = dsu[y]
    if x == y: return -1
    if ranks[x] < ranks[y]: dsu[x] = y
    else:
      dsu[y] = x
      if ranks[x] == ranks[y]: inc ranks[x]
    a[e] = u; b[e] = v
    inc degree[u]; inc degree[v]
    edgeXor[u] = edgeXor[u] xor e
    edgeXor[v] = edgeXor[v] xor e
  degree[root] = 0
  var used = 0
  for start in 0 ..< n:
    var v = start
    while degree[v] == 1:
      let e = edgeXor[v]
      let next = a[e] xor b[e] xor v
      parents[v] = e
      order[used] = v
      inc used
      degree[v] = 0
      dec degree[next]
      edgeXor[next] = edgeXor[next] xor e
      v = next
  order[used] = root
  inc used
  if used != n: return -1
  let bytes = 16 * n
  if output.isNil or capacity < csize_t(bytes): return -2
  for i in 0 ..< 2 * n:
    let value = if i < n: int64(parents[i]) else: int64(order[i - n])
    let bits = cast[uint64](value)
    for byte in 0 ..< 8: output[8 * i + byte] = uint8((bits shr (8 * byte)) and 255)
  int64(bytes)
