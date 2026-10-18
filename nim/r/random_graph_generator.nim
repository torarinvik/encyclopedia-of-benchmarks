const MaxParseableInputLength = 2020
const MaxOutputBytes = 4096
const DrawScale = 9_007_199_254_740_992'i64
const MinProbabilityUnits = -9_007_199_254_740_992'i64
const MaxProbabilityUnits = 18_014_398_509_481_984'i64

proc randomGraphGenerator*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "random_graph_generator".} =
  if input == nil or inputLength < 3 or inputLength > MaxParseableInputLength.csize_t: return -1
  let vertexCountRaw = input[0]
  let directed = input[1]
  let probabilityUnits = input[2]
  if vertexCountRaw < 0 or vertexCountRaw > 64 or (directed != 0 and directed != 1): return -1
  if probabilityUnits < MinProbabilityUnits or probabilityUnits > MaxProbabilityUnits: return -1
  let vertexCount = int(vertexCountRaw)
  let pairCount = if vertexCount < 2: 0 else: vertexCount * (vertexCount - 1) div 2
  let drawCount = if probabilityUnits > 0 and probabilityUnits < DrawScale: pairCount else: 0
  if inputLength != csize_t(3 + drawCount): return -1
  for index in 0 ..< drawCount:
    let draw = input[csize_t(3 + index)]
    if draw < 0 or draw >= DrawScale: return -1

  var staged: array[MaxOutputBytes, uint8]
  if probabilityUnits >= DrawScale:
    for source in 0 ..< vertexCount:
      for target in 0 ..< vertexCount:
        if source != target: staged[source * vertexCount + target] = 1
  elif probabilityUnits > 0:
    var drawIndex = 0
    for source in 0 ..< vertexCount:
      for target in source + 1 ..< vertexCount:
        if input[csize_t(3 + drawIndex)] < probabilityUnits:
          staged[source * vertexCount + target] = 1
          if directed == 0: staged[target * vertexCount + source] = 1
        drawIndex += 1

  let outputBytes = vertexCount * vertexCount
  if output == nil or capacity < csize_t(outputBytes): return -2
  for index in 0 ..< outputBytes: output[index] = staged[index]
  int64(outputBytes)
