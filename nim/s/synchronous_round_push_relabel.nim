const MaxVertices = 8
const MaxArcs = 24
const MaxInputLength = 77
const MaxCapacity = 15'i64

proc synchronous_round_push_relabel*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "synchronous_round_push_relabel".} =
  if input.isNil or length < csize_t(4) or length > csize_t(MaxInputLength): return -1
  let rawN = input[0]
  let rawM = input[1]
  let rawSource = input[2]
  let rawSink = input[3]
  if rawN < 2'i64 or rawN > int64(MaxVertices) or rawM < 0'i64 or rawM > int64(MaxArcs) or
      rawSource < 0'i64 or rawSource >= rawN or rawSink < 0'i64 or rawSink >= rawN or
      rawSource == rawSink or length != csize_t(4 + 3 * rawM): return -1
  let n = int(rawN)
  let m = int(rawM)
  let source = int(rawSource)
  let sink = int(rawSink)
  var capacity: array[MaxVertices * MaxVertices, int64]
  for i in 0..<m:
    let offset = 4 + 3 * i
    let u = input[offset]
    let v = input[offset + 1]
    let c = input[offset + 2]
    if u < 0'i64 or u >= rawN or v < 0'i64 or v >= rawN or u == v or c < 0'i64 or c > MaxCapacity:
      return -1
    capacity[int(u) * MaxVertices + int(v)] += c

  var residual = capacity
  var excess: array[MaxVertices, int64]
  var height: array[MaxVertices, int]
  height[source] = n
  for v in 0..<n:
    if v != source:
      let forward = source * MaxVertices + v
      let reverse = v * MaxVertices + source
      let amount = residual[forward]
      if amount != 0:
        residual[forward] = 0
        residual[reverse] += amount
        excess[source] -= amount
        excess[v] += amount

  while true:
    var active: array[MaxVertices, int]
    var activeCount = 0
    for v in 0..<n:
      if v != source and v != sink and excess[v] > 0 and height[v] < n:
        active[activeCount] = v
        inc activeCount
    if activeCount == 0: return excess[sink]

    var change: array[MaxVertices, int64]
    for ai in 0..<activeCount:
      let u = active[ai]
      var remaining = excess[u]
      for v in 0..<n:
        if remaining <= 0: break
        let forward = u * MaxVertices + v
        let reverse = v * MaxVertices + u
        if residual[forward] > 0 and height[u] == height[v] + 1:
          let amount = min(remaining, residual[forward])
          residual[forward] -= amount
          residual[reverse] += amount
          change[u] -= amount
          change[v] += amount
          remaining -= amount

    var nextExcess: array[MaxVertices, int64]
    var nextHeight = height
    for v in 0..<n:
      nextExcess[v] = excess[v] + change[v]
    for ai in 0..<activeCount:
      let u = active[ai]
      if nextExcess[u] > 0:
        var minimum = 2 * MaxVertices + 1
        for v in 0..<n:
          if residual[u * MaxVertices + v] > 0 and height[v] < minimum:
            minimum = height[v]
        nextHeight[u] = if minimum == 2 * MaxVertices + 1: n + 1 else: minimum + 1
    excess = nextExcess
    height = nextHeight
