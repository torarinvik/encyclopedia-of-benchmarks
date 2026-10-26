# Clean-room bounded SAGA-Bench incremental analytics profile; see package LICENSE.txt.
import math

const MaxN = 8
const MaxE = 28
const MaxInput = 5 + MaxN + 3 * MaxE
const InfValue = 1_000_000_000'i64

proc pushOnce(vertex: int, queue: var array[MaxN, int], count: var int,
    seen: var array[MaxN, bool]) =
  if not seen[vertex]:
    seen[vertex] = true
    queue[count] = vertex
    inc count

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc saga_incremental_analytics*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "saga_incremental_analytics".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let mode64 = input[0]
  let n64 = input[1]
  let base64 = input[2]
  let added64 = input[3]
  let source64 = input[4]
  if mode64 < 1 or mode64 > 6 or n64 < 2 or n64 > int64(MaxN) or
      base64 < 0 or added64 < 1 or base64 + added64 > int64(MaxE) or
      int64(length) != 5 + n64 + 3 * (base64 + added64): return -1
  let mode = int(mode64)
  let n = int(n64)
  let baseEdges = int(base64)
  let edgeCount = int(base64 + added64)
  if mode == 1 or mode == 2 or mode == 5:
    if source64 < 0 or source64 >= n64: return -1
  elif source64 != -1: return -1

  var property: array[MaxN, int64]
  for vertex in 0..<n:
    let value = input[5 + vertex]
    if mode == 1:
      if value < -1 or value >= n64: return -1
    elif mode == 2 or mode == 5:
      if value < -1 or value > InfValue: return -1
    elif mode == 3:
      if value < -1 or value > 1_000_000: return -1
    else:
      if value < -1 or value >= n64: return -1
    property[vertex] = value

  var neighbors: array[MaxN, array[MaxN, int]]
  var weights: array[MaxN, array[MaxN, int64]]
  var degree: array[MaxN, int]
  var edgeSeen: array[MaxN * MaxN, bool]
  var affected: array[MaxN, bool]
  let edgeStart = 5 + n
  for edge in 0..<edgeCount:
    let pos = edgeStart + 3 * edge
    let u64 = input[pos]
    let v64 = input[pos + 1]
    let weight = input[pos + 2]
    if u64 < 0 or v64 <= u64 or v64 >= n64 or weight < 1 or weight > 9: return -1
    let u = int(u64)
    let v = int(v64)
    if edgeSeen[u * MaxN + v]: return -1
    edgeSeen[u * MaxN + v] = true
    edgeSeen[v * MaxN + u] = true
    neighbors[u][degree[u]] = v
    weights[u][degree[u]] = weight
    inc degree[u]
    neighbors[v][degree[v]] = u
    weights[v][degree[v]] = weight
    inc degree[v]
    if edge >= baseEdges:
      affected[u] = true
      affected[v] = true
  if mode == 3:
    for vertex in 0..<n:
      if degree[vertex] == 0: return -1
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2

  if mode == 1 and property[int(source64)] == -1: property[int(source64)] = 0
  if mode == 2 or mode == 5:
    for vertex in 0..<n:
      if property[vertex] == -1:
        if vertex == int(source64):
          property[vertex] = if mode == 2: 0 else: InfValue
        else:
          property[vertex] = if mode == 2: InfValue else: 0
  if mode == 4 or mode == 6:
    for vertex in 0..<n:
      if property[vertex] == -1: property[vertex] = int64(vertex)

  if mode == 3:
    let damping = 0.85'f32
    let baseScore = (1.0'f32 - damping) / float32(n)
    var rank: array[MaxN, float32]
    var contribution: array[MaxN, float32]
    for vertex in 0..<n:
      rank[vertex] = if property[vertex] == -1: 1.0'f32 / float32(n)
                     else: float32(property[vertex]) / 1_000_000.0'f32
      contribution[vertex] = rank[vertex] / float32(degree[vertex])
    var queue: array[MaxN, int]
    var count = 0
    var seen: array[MaxN, bool]
    for vertex in 0..<n:
      if affected[vertex]:
        var incoming = 0.0'f32
        for j in 0..<degree[vertex]: incoming += contribution[neighbors[vertex][j]]
        let old = rank[vertex]
        rank[vertex] = baseScore + damping * incoming
        if abs(rank[vertex] - old) > 1.0e-7'f32:
          for j in 0..<degree[vertex]: pushOnce(neighbors[vertex][j], queue, count, seen)
    var rounds = 0
    while count != 0:
      inc rounds
      if rounds > 256: return -1
      for vertex in 0..<n: contribution[vertex] = rank[vertex] / float32(degree[vertex])
      let current = queue
      let currentCount = count
      count = 0
      seen = default(array[MaxN, bool])
      for q in 0..<currentCount:
        let vertex = current[q]
        var incoming = 0.0'f32
        for j in 0..<degree[vertex]: incoming += contribution[neighbors[vertex][j]]
        let old = rank[vertex]
        rank[vertex] = baseScore + damping * incoming
        if abs(rank[vertex] - old) > 1.0e-7'f32:
          for j in 0..<degree[vertex]: pushOnce(neighbors[vertex][j], queue, count, seen)
    for vertex in 0..<n:
      property[vertex] = int64(floor(rank[vertex] * 1_000_000.0'f32 + 0.5'f32))
  else:
    var active: array[MaxN, int]
    var activeCount = 0
    for vertex in 0..<n:
      if affected[vertex]: active[activeCount] = vertex; inc activeCount
    var first = true
    var rounds = 0
    while activeCount != 0:
      inc rounds
      if rounds > 256: return -1
      var next: array[MaxN, int]
      var nextCount = 0
      var seen: array[MaxN, bool]
      for a in 0..<activeCount:
        let vertex = active[a]
        let old = property[vertex]
        var candidate: int64 = if mode == 1 or mode == 2 or mode == 4: InfValue else: 0
        if mode == 1:
          for j in 0..<degree[vertex]:
            let value = property[neighbors[vertex][j]]
            if value != -1 and value + 1 < candidate: candidate = value + 1
        elif mode == 2:
          for j in 0..<degree[vertex]:
            let value = property[neighbors[vertex][j]] + weights[vertex][j]
            if value < candidate: candidate = value
        elif mode == 4:
          candidate = old
          for j in 0..<degree[vertex]: candidate = min(candidate, property[neighbors[vertex][j]])
        elif mode == 5:
          for j in 0..<degree[vertex]:
            candidate = max(candidate, min(property[neighbors[vertex][j]], weights[vertex][j]))
        else:
          candidate = old
          for j in 0..<degree[vertex]: candidate = max(candidate, property[neighbors[vertex][j]])
        let changed = if mode == 1: candidate != InfValue and (old == -1 or candidate < old)
          elif mode == 2: candidate < old and candidate != InfValue
          elif mode == 4: candidate < old or (first and old == int64(vertex))
          elif mode == 5: candidate > old
          else: candidate > old or (first and old == int64(vertex))
        if changed:
          property[vertex] = candidate
          if mode == 1:
            for j in 0..<degree[vertex]:
              let neighbor = neighbors[vertex][j]
              let update = property[vertex] + 1
              if property[neighbor] == -1 or update < property[neighbor]:
                property[neighbor] = update
                pushOnce(neighbor, next, nextCount, seen)
          else:
            for j in 0..<degree[vertex]: pushOnce(neighbors[vertex][j], next, nextCount, seen)
      active = next
      activeCount = nextCount
      first = false

  for vertex in 0..<n: storeI64LE(output, 8 * vertex, property[vertex])
  int64(outputBytes)
