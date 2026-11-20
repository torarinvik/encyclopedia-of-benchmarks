proc same_value_teleport_bfs*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "same_value_teleport_bfs".} =
  if input.isNil or length < 2 or length > 65: return -2
  if input[0] < 1 or input[0] > 64 or length != csize_t(input[0] + 1): return -2
  let n = int(input[0])
  for i in 0 ..< n:
    if input[i + 1] < -64 or input[i + 1] > 64: return -2
  if n == 1: return 0

  var first: array[129, int]
  var next: array[64, int]
  var queue: array[64, int]
  var distance: array[64, int]
  for i in 0 ..< 129: first[i] = -1
  for i in 0 ..< n:
    let slot = int(input[i + 1] + 64)
    next[i] = first[slot]
    first[slot] = i
    distance[i] = -1
  var front = 0
  var back = 1
  queue[0] = 0
  distance[0] = 0
  while front < back:
    let index = queue[front]
    inc front
    if index == n - 1: return int64(distance[index])
    if index > 0 and distance[index - 1] < 0:
      distance[index - 1] = distance[index] + 1
      queue[back] = index - 1
      inc back
    if index + 1 < n and distance[index + 1] < 0:
      distance[index + 1] = distance[index] + 1
      queue[back] = index + 1
      inc back
    let slot = int(input[index + 1] + 64)
    var member = first[slot]
    if member >= 0:
      first[slot] = -1
      while member >= 0:
        if distance[member] < 0:
          distance[member] = distance[index] + 1
          queue[back] = member
          inc back
        member = next[member]
  int64(distance[n - 1])
