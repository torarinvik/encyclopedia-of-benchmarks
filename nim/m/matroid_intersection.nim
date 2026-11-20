const MaxVertices = 10
const MaxEdges = 20
const MaxColors = 8

proc miIsForest(input: ptr UncheckedArray[int64], vertices, edges, edgeStart: int,
                chosen: openArray[bool], removed, added: int64): bool =
  var parent: array[MaxVertices, int64]
  for vertex in 0..<vertices: parent[vertex] = int64(vertex)
  for edge in 0..<edges:
    if int64(edge) != added and (not chosen[edge] or int64(edge) == removed): continue
    var a = int(input[edgeStart + 3 * edge])
    var b = int(input[edgeStart + 3 * edge + 1])
    while int(parent[a]) != a: a = int(parent[a])
    while int(parent[b]) != b: b = int(parent[b])
    if a == b: return false
    parent[b] = int64(a)
  true

proc miWithinQuotas(input: ptr UncheckedArray[int64], colors, edges, edgeStart: int,
                    chosen: openArray[bool], removed, added: int64): bool =
  var counts: array[MaxColors, int64]
  for edge in 0..<edges:
    if int64(edge) != added and (not chosen[edge] or int64(edge) == removed): continue
    let color = int(input[edgeStart + 3 * edge + 2])
    counts[color] += 1
    if counts[color] > input[3 + color]: return false
  true

proc matroid_intersection*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "matroid_intersection".} =
  if input.isNil or length < csize_t(4) or length > csize_t(72): return -1
  let verticesValue = input[0]
  let edgesValue = input[1]
  let colorsValue = input[2]
  if verticesValue < 1 or verticesValue > MaxVertices or edgesValue < 0 or edgesValue > MaxEdges
      or colorsValue < 1 or colorsValue > MaxColors: return -1
  let vertices = int(verticesValue)
  let edges = int(edgesValue)
  let colors = int(colorsValue)
  if int64(length) != int64(3 + colors + 3 * edges): return -1
  for color in 0..<colors:
    if input[3 + color] < 0 or input[3 + color] > MaxEdges: return -1
  let edgeStart = 3 + colors
  for edge in 0..<edges:
    let u = input[edgeStart + 3 * edge]
    let v = input[edgeStart + 3 * edge + 1]
    let color = input[edgeStart + 3 * edge + 2]
    if u < 0 or u >= verticesValue or v < 0 or v >= verticesValue
        or color < 0 or color >= colorsValue: return -1

  var chosen: array[MaxEdges, bool]
  while true:
    var predecessor: array[MaxEdges, int64]
    for edge in 0..<edges: predecessor[edge] = -2
    var queue: array[MaxEdges, int64]
    var head = 0
    var tail = 0
    for edge in 0..<edges:
      if not chosen[edge] and miIsForest(input, vertices, edges, edgeStart, chosen, -1, int64(edge)):
        predecessor[edge] = -1
        queue[tail] = int64(edge)
        inc tail
    var terminal: int64 = -1
    while head < tail and terminal < 0:
      let current = int(queue[head])
      inc head
      if not chosen[current]:
        if miWithinQuotas(input, colors, edges, edgeStart, chosen, -1, int64(current)):
          terminal = int64(current)
          break
        for inside in 0..<edges:
          if chosen[inside] and predecessor[inside] == -2
              and miWithinQuotas(input, colors, edges, edgeStart, chosen, int64(inside), int64(current)):
            predecessor[inside] = int64(current)
            queue[tail] = int64(inside)
            inc tail
      else:
        for outside in 0..<edges:
          if not chosen[outside] and predecessor[outside] == -2
              and miIsForest(input, vertices, edges, edgeStart, chosen, int64(current), int64(outside)):
            predecessor[outside] = int64(current)
            queue[tail] = int64(outside)
            inc tail
    if terminal < 0: break
    var node = terminal
    while node >= 0:
      chosen[int(node)] = not chosen[int(node)]
      node = predecessor[int(node)]
  var answer: int64 = 0
  for edge in 0..<edges:
    if chosen[edge]: inc answer
  answer
