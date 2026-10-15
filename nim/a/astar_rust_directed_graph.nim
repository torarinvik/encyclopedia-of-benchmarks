proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc astar_rust_directed_graph*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "astar_rust_directed_graph".} =
  if input.isNil or length < 4: return -1
  let vertices64 = input[0]; let edgeCount64 = input[1]
  if vertices64 < 1 or vertices64 > 32 or edgeCount64 < 0 or edgeCount64 > 128: return -1
  let vertices = int(vertices64); let edgeCount = int(edgeCount64)
  if int(length) != 4 + vertices + 3 * edgeCount: return -1
  let start64 = input[2]; let goal64 = input[3]
  if start64 < 0 or start64 >= vertices64 or goal64 < 0 or goal64 >= vertices64: return -1
  let start = int(start64); let goal = int(goal64)
  let edgeBase = 4 + vertices
  for v in 0 ..< vertices:
    if input[4+v] < 0 or input[4+v] > 1_000_000: return -1
  if input[4+goal] != 0: return -1
  for e in 0 ..< edgeCount:
    let from = input[edgeBase+3*e]; let to = input[edgeBase+3*e+1]; let weight = input[edgeBase+3*e+2]
    if from < 0 or from >= vertices64 or to < 0 or to >= vertices64 or weight < 0 or weight > 1_000_000 or input[4+int(from)] > weight + input[4+int(to)]: return -1
  var distance: array[32, int64]; var parent: array[32, int]; var closed: array[32, bool]
  for v in 0 ..< vertices: distance[v] = high(int64); parent[v] = -1
  distance[start] = 0
  for _ in 0 ..< vertices:
    var current = -1
    for v in 0 ..< vertices:
      if closed[v] or distance[v] == high(int64): continue
      if current < 0 or distance[v] + input[4+v] < distance[current] + input[4+current] or
          (distance[v] + input[4+v] == distance[current] + input[4+current] and (distance[v] < distance[current] or (distance[v] == distance[current] and v < current))): current = v
    if current < 0 or current == goal: break
    closed[current] = true
    for e in 0 ..< edgeCount:
      if input[edgeBase+3*e] != int64(current): continue
      let next = int(input[edgeBase+3*e+1]); let candidate = distance[current] + input[edgeBase+3*e+2]
      if not closed[next] and candidate < distance[next]: distance[next] = candidate; parent[next] = current
  if distance[goal] == high(int64): return 0
  var reversed: array[32, int64]; var pathLength = 0; var current = goal
  while pathLength < vertices:
    reversed[pathLength] = int64(current); inc pathLength
    if current == start: break
    current = parent[current]; if current < 0: return -1
  if reversed[pathLength-1] != start64: return -1
  let required = 8 * (pathLength + 2)
  if output.isNil or int(capacity) < required: return -2
  putI64Le(output, 0, distance[goal]); putI64Le(output, 8, int64(pathLength))
  for i in 0 ..< pathLength: putI64Le(output, 16 + i*8, reversed[pathLength-1-i])
  int64(required)
