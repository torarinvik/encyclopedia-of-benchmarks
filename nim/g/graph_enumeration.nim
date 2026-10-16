proc graph_enumeration(a: ptr UncheckedArray[int64], length: int): int64 {.exportc, cdecl.} =
  if a == nil or length < 1: return -1
  let n0 = a[0]
  if n0 < 0 or n0 > 16 or length < 1 + int(n0): return -1
  let n = int(n0)
  var labels, sorted: array[16, int64]
  var adjacency: array[16, array[32, int64]]
  var degree: array[16, int]
  var off = 1 + n
  for i in 0 ..< n:
    labels[i] = a[1+i]
    if labels[i] < -1_000_000 or labels[i] > 1_000_000: return -1
    for j in 0 ..< i:
      if labels[j] == labels[i]: return -1
    sorted[i] = labels[i]
  for i in 0 ..< n:
    for j in i+1 ..< n:
      if sorted[j] < sorted[i]: swap(sorted[i], sorted[j])
  for i in 0 ..< n:
    if off >= length: return -1
    let d = a[off]; inc off
    if d < 0 or d > 32 or off + int(d) > length: return -1
    degree[i] = int(d)
    for j in 0 ..< int(d):
      let x = a[off]; inc off
      var found = false
      for k in 0 ..< n:
        if labels[k] == x: found = true
      if not found: return -1
      adjacency[i][j] = x
  if off != length: return -1
  var h = 14695981039346656037'u64
  template mix(v: int64) =
    var z = cast[uint64](v)
    for b in 0 ..< 8:
      h = (h xor (z and 255'u64)) * 1099511628211'u64
      z = z shr 8
  mix(int64(n+1)); mix(0)
  for s in 0 ..< n:
    var i = 0
    while labels[i] != sorted[s]: inc i
    mix(int64(degree[i]))
    for j in 0 ..< degree[i]:
      var k = 0
      while sorted[k] != adjacency[i][j]: inc k
      mix(int64(k+1))
  cast[int64](h)
