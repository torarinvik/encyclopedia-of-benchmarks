const MaxN = 8
const MaxEdges = 28
const MaxInput = 10

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc havel_hakimi_graph_realization*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "havel_hakimi_graph_realization".} =
  if input == nil or length < 1 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN: return -1
  let n = int(nValue)
  if length != csize_t(n + 1): return -1
  var residual: array[MaxN, int]
  var active: array[MaxN, bool]
  for v in 0 ..< n:
    let d = input[v + 1]
    if d < 0 or d >= nValue: return -1
    residual[v] = int(d); active[v] = true
  var left: array[MaxEdges, int64]
  var right: array[MaxEdges, int64]
  var edgeCount = 0
  var graphical = true
  while graphical:
    var hub = -1
    for v in 0 ..< n:
      if active[v] and residual[v] > 0 and
          (hub < 0 or residual[v] > residual[hub] or (residual[v] == residual[hub] and v < hub)):
        hub = v
    if hub < 0: break
    let d = residual[hub]
    residual[hub] = 0; active[hub] = false
    var candidates: array[MaxN, int]
    var candidateCount = 0
    for v in 0 ..< n:
      if active[v]: candidates[candidateCount] = v; inc candidateCount
    for i in 1 ..< candidateCount:
      let value = candidates[i]
      var j = i
      while j > 0 and (residual[candidates[j - 1]] < residual[value] or
          (residual[candidates[j - 1]] == residual[value] and candidates[j - 1] > value)):
        candidates[j] = candidates[j - 1]; dec j
      candidates[j] = value
    if d > candidateCount:
      graphical = false
      break
    for i in 0 ..< d:
      let neighbor = candidates[i]
      if residual[neighbor] == 0:
        graphical = false
        break
      dec residual[neighbor]
      left[edgeCount] = int64(min(hub, neighbor)); right[edgeCount] = int64(max(hub, neighbor)); inc edgeCount
  var words: array[2 + 2 * MaxEdges, int64]
  var wordCount = 0
  if graphical:
    words[0] = 1; words[1] = int64(edgeCount); wordCount = 2 + 2 * edgeCount
    for i in 0 ..< edgeCount:
      words[2 + 2 * i] = left[i]; words[3 + 2 * i] = right[i]
  else:
    words[0] = 0; wordCount = 1
  let byteCount = wordCount * 8
  if output == nil or capacity < csize_t(byteCount): return -2
  for i in 0 ..< wordCount: storeI64(output, 8 * i, words[i])
  int64(byteCount)
