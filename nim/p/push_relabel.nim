const MaxVertices = 14
const AugmentedVertices = 16
const MaxInputLength = 227
const MaxCapacity = 1_000_000'i64

proc push_relabel*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "push_relabel".} =
  if input.isNil or length < 3 or length > MaxInputLength: return -1
  let n64 = input[0]
  let sourceCount64 = input[1]
  if n64 < 2 or n64 > MaxVertices or sourceCount64 < 1 or sourceCount64 >= n64: return -1
  let n = int(n64)
  let sourceCount = int(sourceCount64)
  let sinkCountIndex = 2 + sourceCount
  if length <= csize_t(sinkCountIndex): return -1

  var isSource: array[MaxVertices, bool]
  var isSink: array[MaxVertices, bool]
  var sources: array[MaxVertices, int]
  for index in 0 ..< sourceCount:
    let node64 = input[2 + index]
    if node64 < 0 or node64 >= n64 or isSource[int(node64)]: return -1
    sources[index] = int(node64)
    isSource[int(node64)] = true
  let sinkCount64 = input[sinkCountIndex]
  if sinkCount64 < 1 or sinkCount64 > n64 - sourceCount64: return -1
  let sinkCount = int(sinkCount64)
  let matrixStart = sinkCountIndex + 1 + sinkCount
  if length < csize_t(matrixStart) or length != csize_t(matrixStart + n * n): return -1
  for index in 0 ..< sinkCount:
    let node64 = input[sinkCountIndex + 1 + index]
    if node64 < 0 or node64 >= n64 or isSink[int(node64)] or isSource[int(node64)]: return -1
    isSink[int(node64)] = true

  var residual: array[AugmentedVertices * AugmentedVertices, int64]
  var sourceOut: array[MaxVertices, int64]
  var flowLimit = 0'i64
  for row in 0 ..< n:
    for column in 0 ..< n:
      let capacity = input[matrixStart + row * n + column]
      if capacity < 0 or capacity > MaxCapacity or (row == column and capacity != 0): return -1
      residual[row * AugmentedVertices + column] = capacity
      if isSource[row]:
        sourceOut[row] += capacity
        flowLimit += capacity

  let superSource = n
  let superSink = n + 1
  for index in 0 ..< sourceCount:
    residual[superSource * AugmentedVertices + sources[index]] = sourceOut[sources[index]]
  for index in 0 ..< sinkCount:
    let sink = int(input[sinkCountIndex + 1 + index])
    residual[sink * AugmentedVertices + superSink] = flowLimit

  var height: array[AugmentedVertices, int]
  var excess: array[AugmentedVertices, int64]
  var active: array[AugmentedVertices, bool]
  height[superSource] = n + 2
  for index in 0 ..< sourceCount:
    let source = sources[index]
    let initialExcess = residual[superSource * AugmentedVertices + source]
    residual[superSource * AugmentedVertices + source] = 0
    residual[source * AugmentedVertices + superSource] += initialExcess
    excess[source] += initialExcess
    if excess[source] > 0: active[source] = true

  while true:
    var node = 0
    while node < n and not active[node]: inc node
    if node == n: break
    active[node] = false
    while excess[node] > 0:
      var pushed = false
      for neighbor in 0 ..< n + 2:
        if excess[node] == 0: break
        let edge = node * AugmentedVertices + neighbor
        if residual[edge] <= 0 or height[node] != height[neighbor] + 1: continue
        let amount = min(excess[node], residual[edge])
        residual[edge] -= amount
        residual[neighbor * AugmentedVertices + node] += amount
        excess[node] -= amount
        let previousExcess = excess[neighbor]
        excess[neighbor] += amount
        if neighbor < n and previousExcess == 0: active[neighbor] = true
        pushed = true
      if excess[node] > 0 and not pushed:
        var minimumHeight = 1000
        for neighbor in 0 ..< n + 2:
          if residual[node * AugmentedVertices + neighbor] > 0 and height[neighbor] < minimumHeight:
            minimumHeight = height[neighbor]
        if minimumHeight == 1000: return -1
        height[node] = minimumHeight + 1
  return excess[superSink]
