## Uncompiled exact-length shortest-walk draft.
const inf = 1_000_000_000_000_000'i64
proc fixed_length_walk_minplus*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fixed_length_walk_minplus".} =
  if input == nil or length < 4 or length > 261: return -100_000_002
  let nv = input[0]
  var k = input[1]
  let source = input[2]
  let target = input[3]
  if nv < 1 or nv > 16 or k < 0 or k > 1_000_000 or source < 0 or source >= nv or
      target < 0 or target >= nv or length != csize_t(4 + nv * nv): return -100_000_002
  let n = int(nv)
  var matrix: array[16, array[16, int64]]
  var distance: array[16, int64]
  for i in 0 ..< n:
    distance[i] = inf
    for j in 0 ..< n:
      let weight = input[4 + i*n+j]
      if weight != 1_000_000 and (weight < -100 or weight > 100): return -100_000_002
      matrix[i][j] = if weight == 1_000_000: inf else: weight
  distance[int(source)] = 0
  while k > 0:
    if (k and 1) != 0:
      var next: array[16, int64]
      for j in 0 ..< n:
        next[j] = inf
        for i in 0 ..< n:
          if distance[i] != inf and matrix[i][j] != inf:
            next[j] = min(next[j], distance[i] + matrix[i][j])
      distance = next
    k = k shr 1
    if k > 0:
      var next: array[16, array[16, int64]]
      for i in 0 ..< n:
        for j in 0 ..< n:
          next[i][j] = inf
          for p in 0 ..< n:
            if matrix[i][p] != inf and matrix[p][j] != inf:
              next[i][j] = min(next[i][j], matrix[i][p] + matrix[p][j])
      matrix = next
  if distance[int(target)] == inf: -100_000_001 else: distance[int(target)]
