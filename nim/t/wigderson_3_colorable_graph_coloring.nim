const MaxVertices = 32
const MaxEdges = 128
const MaxInput = 2 + 2 * MaxEdges

proc wigderson_3_colorable_graph_coloring*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "wigderson_3_colorable_graph_coloring".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput + 1): return -1
  if input[0] < 0 or input[0] > int64(MaxVertices) or
      input[1] < 0 or input[1] > int64(MaxEdges): return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + 2 * m: return -1

  var adjacent: array[MaxVertices, array[MaxVertices, bool]]
  for edge in 0 ..< m:
    let rawU = input[2 + 2 * edge]
    let rawV = input[3 + 2 * edge]
    if rawU < 0 or rawV <= rawU or rawV >= int64(n): return -1
    let u = int(rawU)
    let v = int(rawV)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true
    adjacent[v][u] = true

  var active: array[MaxVertices, bool]
  var colors: array[MaxVertices, uint8]
  for v in 0 ..< n: active[v] = true
  var threshold = 0
  while (threshold + 1) * (threshold + 1) <= n: inc threshold
  var nextColor = 1

  while true:
    var chosen = n
    var maximumDegree = 0
    for v in 0 ..< n:
      if not active[v]: continue
      var degree = 0
      for w in 0 ..< n:
        if active[w] and adjacent[v][w]: inc degree
      if chosen == n or degree > maximumDegree:
        chosen = v
        maximumDegree = degree
    if chosen == n or maximumDegree < threshold: break

    var inNeighborhood: array[MaxVertices, bool]
    var side: array[MaxVertices, int8]
    var queue: array[MaxVertices, int]
    for v in 0 ..< n:
      side[v] = -1
      inNeighborhood[v] = active[v] and adjacent[chosen][v]
    for root in 0 ..< n:
      if not inNeighborhood[root] or side[root] >= 0: continue
      var head = 0
      var tail = 0
      side[root] = 0
      queue[tail] = root
      inc tail
      while head < tail:
        let u = queue[head]
        inc head
        for v in 0 ..< n:
          if not inNeighborhood[v] or not adjacent[u][v]: continue
          if side[v] < 0:
            side[v] = 1 - side[u]
            queue[tail] = v
            inc tail
          elif side[v] == side[u]: return -1
    for v in 0 ..< n:
      if inNeighborhood[v]: colors[v] = uint8(nextColor + int(side[v]))
    colors[chosen] = uint8(nextColor + 2)
    active[chosen] = false
    for v in 0 ..< n:
      if adjacent[chosen][v]: active[v] = false
    nextColor += 2

  for v in 0 ..< n:
    if not active[v]: continue
    var used: array[MaxVertices + 2, bool]
    for w in 0 ..< n:
      if adjacent[v][w] and colors[w] > 0: used[int(colors[w])] = true
    var candidate = nextColor
    while candidate < used.len and used[candidate]: inc candidate
    if candidate >= used.len: return -1
    colors[v] = uint8(candidate)

  var palette: uint8 = 0
  for v in 0 ..< n:
    if colors[v] > palette: palette = colors[v]
  let outputBytes = n + 1
  if output.isNil or capacity < csize_t(outputBytes): return -2
  output[0] = palette
  for v in 0 ..< n: output[v + 1] = colors[v]
  int64(outputBytes)
