proc directed_girth_bfs*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "directed_girth_bfs".} =
  if input.isNil or length < 2 or length > 131: return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 64: return -1
  let n = int(input[0])
  let m = int(input[1])
  if length != csize_t(2 + 2*m): return -1
  var outgoing: array[16, uint32]
  for i in 0 ..< m:
    let u = input[2+2*i]
    let v = input[3+2*i]
    if u < 0 or v < 0 or u >= int64(n) or v >= int64(n): return -1
    outgoing[int(u)] = outgoing[int(u)] or (1'u32 shl int(v))
  var best = 17
  for start in 0 ..< n:
    var distance: array[16, int]
    var queue: array[16, int]
    for i in 0 ..< n: distance[i] = -1
    distance[start] = 0
    queue[0] = start
    var head = 0
    var tail = 1
    while head < tail:
      let u = queue[head]
      inc head
      for v in 0 ..< n:
        if (outgoing[u] and (1'u32 shl v)) != 0:
          if v == start:
            if distance[u] + 1 < best: best = distance[u] + 1
          elif distance[v] < 0:
            distance[v] = distance[u] + 1
            queue[tail] = v
            inc tail
  if best == 17: return 0
  int64(best)
