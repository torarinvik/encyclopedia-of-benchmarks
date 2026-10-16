const MAX_VERTICES = 14

proc greedy_graph_coloring*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "greedy_graph_coloring".} =
  if values == nil or length < 1 or length > MAX_VERTICES + 1:
    return -1
  let countValue = values[0]
  if countValue < 0 or countValue > MAX_VERTICES or length != csize_t(countValue + 1):
    return -1
  let count = int(countValue)
  let limit = (1'i64 shl count) - 1
  var adjacency, degree, order, colors: array[MAX_VERTICES, int64]
  for vertex in 0 ..< count:
    let mask = values[1 + vertex]
    if mask < 0 or mask > limit or (mask and (1'i64 shl vertex)) != 0:
      return -1
    adjacency[vertex] = mask
    order[vertex] = int64(vertex)
    var remaining = mask
    while remaining != 0:
      remaining = remaining and (remaining - 1)
      inc degree[vertex]
  for vertex in 0 ..< count:
    for other in 0 ..< count:
      if ((adjacency[vertex] shr other) and 1) != ((adjacency[other] shr vertex) and 1):
        return -1
  for index in 1 ..< count:
    let current = order[index]
    var position = index
    while position > 0 and degree[int(order[position - 1])] < degree[int(current)]:
      order[position] = order[position - 1]
      dec position
    order[position] = current

  var colorCount = 0'i64
  for position in 0 ..< count:
    let vertex = int(order[position])
    var used = 0'i64
    for other in 0 ..< count:
      if (adjacency[vertex] and (1'i64 shl other)) != 0 and colors[other] != 0:
        used = used or (1'i64 shl int(colors[other]))
    var color = 1'i64
    while (used and (1'i64 shl int(color))) != 0:
      inc color
    colors[vertex] = color
    colorCount = max(colorCount, color)
  var packed = colorCount
  for vertex in 0 ..< count:
    packed = packed or (colors[vertex] shl (4 * (vertex + 1)))
  packed
