# Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt.
const MaxN = 16
const MaxM = 64
const MaxSamples = 64
const MaxInput = 3 + MaxSamples + 2 * MaxM

proc linkComponents(u, v: int, component: var array[MaxN, int]) =
  var p1 = component[u]
  var p2 = component[v]
  while p1 != p2:
    let high = max(p1, p2)
    let low = min(p1, p2)
    let parentHigh = component[high]
    if parentHigh == low: break
    if parentHigh == high:
      component[high] = low
      break
    p1 = component[component[high]]
    p2 = component[low]

proc compressComponents(n: int, component: var array[MaxN, int]) =
  for vertex in 0..<n:
    while component[vertex] != component[component[vertex]]:
      component[vertex] = component[component[vertex]]

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc gapbs_afforest_components*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gapbs_afforest_components".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  let sampleCount64 = input[2]
  if n64 < 1 or n64 > int64(MaxN) or m64 < 0 or m64 > int64(MaxM) or
      sampleCount64 < 1 or sampleCount64 > int64(MaxSamples): return -1
  let n = int(n64)
  let m = int(m64)
  let sampleCount = int(sampleCount64)
  if int64(length) != 3 + sampleCount64 + 2 * m64: return -1
  var samples: array[MaxSamples, int]
  for i in 0..<sampleCount:
    let sample = input[3 + i]
    if sample < 0 or sample >= n64: return -1
    samples[i] = int(sample)
  var adjacency: array[MaxN * MaxN, bool]
  for edge in 0..<m:
    let pos = 3 + sampleCount + 2 * edge
    let u = input[pos]
    let v = input[pos + 1]
    if u < 0 or v <= u or v >= n64 or adjacency[int(u) * MaxN + int(v)]: return -1
    adjacency[int(u) * MaxN + int(v)] = true
    adjacency[int(v) * MaxN + int(u)] = true
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var neighbors: array[MaxN * MaxN, int]
  var degree: array[MaxN, int]
  for u in 0..<n:
    for v in 0..<n:
      if adjacency[u * MaxN + v]:
        neighbors[u * MaxN + degree[u]] = v
        inc degree[u]
  var component: array[MaxN, int]
  for vertex in 0..<n: component[vertex] = vertex
  for round in 0..<2:
    for u in 0..<n:
      if degree[u] > round: linkComponents(u, neighbors[u * MaxN + round], component)
    compressComponents(n, component)
  var sampleCounts: array[MaxN, int]
  for i in 0..<sampleCount: inc sampleCounts[component[samples[i]]]
  var skipLabel = 0
  for label in 1..<n:
    if sampleCounts[label] > sampleCounts[skipLabel]: skipLabel = label
  var skipIsSafe = true
  for u in 0..<n:
    if component[u] != skipLabel: continue
    for offset in 2..<degree[u]:
      if component[neighbors[u * MaxN + offset]] != skipLabel:
        skipIsSafe = false
        break
    if not skipIsSafe: break
  for u in 0..<n:
    if skipIsSafe and component[u] == skipLabel: continue
    for offset in 2..<degree[u]:
      linkComponents(u, neighbors[u * MaxN + offset], component)
  compressComponents(n, component)
  for vertex in 0..<n: storeI64LE(output, 8 * vertex, int64(component[vertex]))
  int64(outputBytes)
