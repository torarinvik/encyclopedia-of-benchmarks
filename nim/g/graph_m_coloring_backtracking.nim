const MaxVertices = 12

proc assignColors(input: ptr UncheckedArray[int64], count, maxColors, vertex: int,
    colors: ptr UncheckedArray[int64]): bool =
  if vertex == count: return true
  for color in 0 ..< maxColors:
    var safe = true
    for neighbor in 0 ..< count:
      if input[2 + vertex * count + neighbor] == 1 and colors[neighbor] == int64(color):
        safe = false
        break
    if not safe: continue
    colors[vertex] = int64(color)
    if assignColors(input, count, maxColors, vertex + 1, colors): return true
    colors[vertex] = -1
  false

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc graph_m_coloring_backtracking*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "graph_m_coloring_backtracking".} =
  if input == nil or length < 2: return -1
  let nValue = input[0]
  let maxColorsValue = input[1]
  if nValue < 0 or nValue > MaxVertices or maxColorsValue < 0 or maxColorsValue > MaxVertices: return -1
  let n = int(nValue)
  let maxColors = int(maxColorsValue)
  if length != csize_t(2 + n * n): return -1
  for row in 0 ..< n:
    if input[2 + row * n + row] != 0: return -1
    for column in 0 ..< n:
      let cell = input[2 + row * n + column]
      if (cell != 0 and cell != 1) or cell != input[2 + column * n + row]: return -1
  var colors: array[MaxVertices, int64]
  for vertex in 0 ..< n: colors[vertex] = -1
  if not assignColors(input, n, maxColors, 0, cast[ptr UncheckedArray[int64]](addr colors[0])): return 0
  let required = n * 8
  if required == 0: return 0
  if output == nil or capacity < csize_t(required): return -2
  for vertex in 0 ..< n: putI64(output, vertex * 8, colors[vertex])
  int64(required)
