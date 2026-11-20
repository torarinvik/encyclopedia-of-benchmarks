const MaxVertices = 12
const MaxEdges = 66
const MaxParseableInputLength = 135

proc bitCount(maskValue: uint16): int =
  var mask = maskValue
  while mask != 0'u16:
    inc result
    mask = mask and (mask - 1'u16)

proc dsatur_greedy_coloring*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dsatur_greedy_coloring".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseableInputLength): return -1
  let vertexValue = input[0]
  let edgeValue = input[1]
  if vertexValue < 1'i64 or vertexValue > int64(MaxVertices) or
      edgeValue < 0'i64 or edgeValue > int64(MaxEdges): return -1
  let n = int(vertexValue)
  let m = int(edgeValue)
  if length != csize_t(2 + 2 * m): return -1

  var adjacency: array[MaxVertices, uint16]
  for edge in 0..<m:
    let uValue = input[2 + 2 * edge]
    let vValue = input[3 + 2 * edge]
    if uValue < 0'i64 or vValue <= uValue or vValue >= vertexValue: return -1
    let u = int(uValue)
    let v = int(vValue)
    let vBit = 1'u16 shl v
    if (adjacency[u] and vBit) != 0'u16: return -1
    adjacency[u] = adjacency[u] or vBit
    adjacency[v] = adjacency[v] or (1'u16 shl u)

  var colors: array[MaxVertices, int]
  var saturationColors: array[MaxVertices, uint16]
  var residualDegree: array[MaxVertices, int]
  for vertex in 0..<n:
    colors[vertex] = -1
    residualDegree[vertex] = bitCount(adjacency[vertex])

  var colorCount = 0
  for _ in 0..<n:
    var selected = -1
    var selectedSaturation = -1
    var selectedDegree = -1
    for vertex in 0..<n:
      if colors[vertex] >= 0: continue
      let saturation = bitCount(saturationColors[vertex])
      let degree = residualDegree[vertex]
      if selected < 0 or saturation > selectedSaturation or
          (saturation == selectedSaturation and degree > selectedDegree) or
          (saturation == selectedSaturation and degree == selectedDegree and vertex < selected):
        selected = vertex
        selectedSaturation = saturation
        selectedDegree = degree

    let usedColors = saturationColors[selected]
    var color = 0
    while color < MaxVertices and (usedColors and (1'u16 shl color)) != 0'u16:
      inc color
    if color >= MaxVertices: return -1
    colors[selected] = color
    if color + 1 > colorCount: colorCount = color + 1
    let colorBit = 1'u16 shl color
    for neighbor in 0..<n:
      if colors[neighbor] < 0 and (adjacency[selected] and (1'u16 shl neighbor)) != 0'u16:
        dec residualDegree[neighbor]
        saturationColors[neighbor] = saturationColors[neighbor] or colorBit

  var packed = int64(colorCount) shl 48
  for vertex in 0..<n:
    packed = packed or (int64(colors[vertex]) shl (4 * vertex))
  packed
