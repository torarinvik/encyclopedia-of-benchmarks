proc incremental_minimum_spanning_forest*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "incremental_minimum_spanning_forest".} =
  if input == nil or length < 2 or length > 98: return -1
  if input[0] < 1 or input[0] > 16 or input[1] < 1 or input[1] > 32: return -1
  let n = int(input[0])
  let m = int(input[1])
  if int(length) != 2 + 3 * m: return -1
  for i in 0 ..< m:
    let u = input[2 + 3*i]
    let v = input[3 + 3*i]
    let weight = input[4 + 3*i]
    if u < 0 or u >= int64(n) or v < 0 or v >= int64(n) or weight < 1 or weight > 1000000: return -1
    for j in 0 ..< i:
      if input[4 + 3*j] == weight: return -1
  var active: array[32, bool]
  var answers: array[32, int64]
  for edge in 0 ..< m:
    let start = int(input[2 + 3*edge])
    let target = int(input[3 + 3*edge])
    if start == target:
      answers[edge] = int64(edge)
      continue
    var parent: array[16, int]
    var parentEdge: array[16, int]
    var queue: array[16, int]
    for i in 0 ..< n: parent[i] = -1
    var head = 0
    var tail = 1
    parent[start] = start
    queue[0] = start
    while head < tail:
      let vertex = queue[head]
      inc head
      for i in 0 ..< edge:
        if not active[i]: continue
        let u = int(input[2 + 3*i])
        let v = int(input[3 + 3*i])
        var neighbor = -1
        if u == vertex: neighbor = v
        elif v == vertex: neighbor = u
        if neighbor >= 0 and parent[neighbor] < 0:
          parent[neighbor] = vertex
          parentEdge[neighbor] = i
          queue[tail] = neighbor
          inc tail
    if parent[target] < 0:
      active[edge] = true
      answers[edge] = -1
      continue
    var node = target
    var heaviest = parentEdge[node]
    while node != start:
      let i = parentEdge[node]
      if input[4 + 3*i] > input[4 + 3*heaviest]: heaviest = i
      node = parent[node]
    if input[4 + 3*edge] < input[4 + 3*heaviest]:
      active[heaviest] = false
      active[edge] = true
      answers[edge] = int64(heaviest)
    else: answers[edge] = int64(edge)
  let bytes = 8 * m
  if output == nil or capacity < csize_t(bytes): return -2
  for i in 0 ..< m:
    let bits = cast[uint64](answers[i])
    for b in 0 ..< 8: output[8*i+b] = uint8((bits shr (8*b)) and 255)
  return int64(bytes)
