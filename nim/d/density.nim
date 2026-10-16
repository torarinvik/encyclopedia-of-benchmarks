const InvalidResult = -1.0e300
const MaxNodes = 100000'i64

proc density*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "density".} =
  if values.isNil or length != 3: return InvalidResult
  let nodes = values[0]
  let edges = values[1]
  let directed = values[2]
  if nodes < 2 or nodes > MaxNodes or (directed != 0 and directed != 1): return InvalidResult
  var maxEdges = nodes * (nodes - 1)
  if directed == 0: maxEdges = maxEdges div 2
  if edges < 0 or edges > maxEdges: return InvalidResult
  let factor = if directed == 1: 1.0 else: 2.0
  (factor * float64(edges)) / (float64(nodes) * float64(nodes - 1))
