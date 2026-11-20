import std/math

const
  MaxV = 24
  MaxF = 8
  MaxD = 8
  MaxE = 32
  MaxInput = 122
  MaxOutput = 386

type CcEdge = object
  u, v, f0, f1, uses: int

proc ccInteger(value: float64, low, high: int): int =
  if not value.isFinite or trunc(value) != value or value < float64(low) or value > float64(high): return -1
  int(value)

proc ccMean(values: array[MaxF, float64], count: int): float64 =
  var scale = 0.0
  for i in 0..<count: scale = max(scale, abs(values[i]))
  if scale == 0.0: return 0.0
  var total = 0.0
  for i in 0..<count: total += values[i] / scale
  (total / float64(count)) * scale

proc ccMidpoint(a, b: float64): float64 =
  let scale = max(abs(a), abs(b))
  if scale == 0.0: return 0.0
  ((a / scale + b / scale) * 0.5) * scale

proc ccAverage4(a, b, c, d: float64): float64 =
  let scale = max(max(abs(a), abs(b)), max(abs(c), abs(d)))
  if scale == 0.0: return 0.0
  ((a / scale + b / scale + c / scale + d / scale) * 0.25) * scale

proc catmull_clark_subdivision*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let inputLen = int(length)
  for i in 0..<inputLen:
    if not input[i].isFinite: return -1
  let nv = ccInteger(input[0], 0, MaxV)
  let nf = ccInteger(input[1], 0, MaxF)
  if nv < 0 or nf < 0: return -1
  if (nv == 0 or nf == 0) and not (nv == 0 and nf == 0 and inputLen == 2): return -1

  var x: array[MaxV, float64]
  var y: array[MaxV, float64]
  var degree: array[MaxF, int]
  var face: array[MaxF, array[MaxD, int]]
  var pos = 2
  if pos + 2 * nv > inputLen: return -1
  for v in 0..<nv:
    x[v] = input[pos]
    y[v] = input[pos + 1]
    pos += 2

  var edges: array[MaxE, CcEdge]
  var edgeCount = 0
  for f in 0..<nf:
    if pos >= inputLen: return -1
    degree[f] = ccInteger(input[pos], 3, MaxD)
    pos += 1
    if degree[f] < 0 or pos + degree[f] > inputLen: return -1
    for i in 0..<degree[f]:
      face[f][i] = ccInteger(input[pos], 0, nv - 1)
      pos += 1
      if face[f][i] < 0: return -1
      for j in 0..<i:
        if face[f][i] == face[f][j]: return -1
    for i in 0..<degree[f]:
      let a = face[f][i]
      let b = face[f][(i + 1) mod degree[f]]
      let u = min(a, b)
      let v = max(a, b)
      var found = -1
      for e in 0..<edgeCount:
        if edges[e].u == u and edges[e].v == v:
          found = e
          break
      if found < 0:
        if edgeCount == MaxE: return -1
        edges[edgeCount] = CcEdge(u: u, v: v, f0: f, f1: -1, uses: 1)
        edgeCount += 1
      else:
        if edges[found].uses != 1 or edges[found].f0 == f: return -1
        edges[found].uses = 2
        edges[found].f1 = f
  if pos != inputLen: return -1
  for e in 0..<edgeCount:
    if edges[e].uses != 2: return -1

  for vertex in 0..<nv:
    var valence = 0
    for e in 0..<edgeCount:
      if edges[e].u == vertex or edges[e].v == vertex: inc valence
    var linkA: array[MaxF, int]
    var linkB: array[MaxF, int]
    var links = 0
    for f in 0..<nf:
      for i in 0..<degree[f]:
        if face[f][i] == vertex:
          let a = face[f][(i + degree[f] - 1) mod degree[f]]
          let b = face[f][(i + 1) mod degree[f]]
          let lo = min(a, b)
          let hi = max(a, b)
          for j in 0..<links:
            if min(linkA[j], linkB[j]) == lo and max(linkA[j], linkB[j]) == hi: return -1
          linkA[links] = a
          linkB[links] = b
          inc links
    if valence < 3 or links != valence: return -1
    var reached: array[MaxV, bool]
    reached[linkA[0]] = true
    var changed = true
    while changed:
      changed = false
      for i in 0..<links:
        if reached[linkA[i]] and not reached[linkB[i]]:
          reached[linkB[i]] = true
          changed = true
        if reached[linkB[i]] and not reached[linkA[i]]:
          reached[linkA[i]] = true
          changed = true
    var nodeDegree: array[MaxV, int]
    for i in 0..<links:
      inc nodeDegree[linkA[i]]
      inc nodeDegree[linkB[i]]
    var nodes = 0
    for u in 0..<nv:
      if nodeDegree[u] != 0:
        inc nodes
        if nodeDegree[u] != 2 or not reached[u]: return -1
    if nodes < 3: return -1

  for i in 1..<edgeCount:
    let item = edges[i]
    var j = i
    while j > 0 and (edges[j - 1].u > item.u or
        (edges[j - 1].u == item.u and edges[j - 1].v > item.v)):
      edges[j] = edges[j - 1]
      dec j
    edges[j] = item

  var faceX: array[MaxF, float64]
  var faceY: array[MaxF, float64]
  for f in 0..<nf:
    var vx: array[MaxF, float64]
    var vy: array[MaxF, float64]
    for i in 0..<degree[f]:
      vx[i] = x[face[f][i]]
      vy[i] = y[face[f][i]]
    faceX[f] = ccMean(vx, degree[f])
    faceY[f] = ccMean(vy, degree[f])

  var staged: array[MaxOutput, float64]
  var out = 0
  let newV = nv + edgeCount + nf
  var newF = 0
  for f in 0..<nf: newF += degree[f]
  staged[out] = float64(newV); inc out
  staged[out] = float64(newF); inc out
  for vertex in 0..<nv:
    var fxs: array[MaxF, float64]
    var fys: array[MaxF, float64]
    var rx: array[MaxF, float64]
    var ry: array[MaxF, float64]
    var nfi = 0
    var nei = 0
    for f in 0..<nf:
      for i in 0..<degree[f]:
        if face[f][i] == vertex:
          fxs[nfi] = faceX[f]
          fys[nfi] = faceY[f]
          inc nfi
          break
    for e in 0..<edgeCount:
      if edges[e].u == vertex or edges[e].v == vertex:
        rx[nei] = ccMidpoint(x[edges[e].u], x[edges[e].v])
        ry[nei] = ccMidpoint(y[edges[e].u], y[edges[e].v])
        inc nei
    let faX = ccMean(fxs, nfi)
    let faY = ccMean(fys, nfi)
    let raX = ccMean(rx, nei)
    let raY = ccMean(ry, nei)
    let sx = max(abs(x[vertex]), max(abs(faX), abs(raX)))
    let sy = max(abs(y[vertex]), max(abs(faY), abs(raY)))
    var px = 0.0
    var py = 0.0
    if sx != 0.0: px = ((faX / sx + 2 * raX / sx + float64(nei - 3) * (x[vertex] / sx)) / float64(nei)) * sx
    if sy != 0.0: py = ((faY / sy + 2 * raY / sy + float64(nei - 3) * (y[vertex] / sy)) / float64(nei)) * sy
    staged[out] = px; inc out
    staged[out] = py; inc out
  for e in 0..<edgeCount:
    staged[out] = ccAverage4(x[edges[e].u], x[edges[e].v], faceX[edges[e].f0], faceX[edges[e].f1]); inc out
    staged[out] = ccAverage4(y[edges[e].u], y[edges[e].v], faceY[edges[e].f0], faceY[edges[e].f1]); inc out
  for f in 0..<nf:
    staged[out] = faceX[f]; inc out
    staged[out] = faceY[f]; inc out
  for f in 0..<nf:
    for i in 0..<degree[f]:
      let vertex = face[f][i]
      let next = face[f][(i + 1) mod degree[f]]
      let prev = face[f][(i + degree[f] - 1) mod degree[f]]
      let nextLo = min(vertex, next); let nextHi = max(vertex, next)
      let prevLo = min(prev, vertex); let prevHi = max(prev, vertex)
      var en = 0; var ep = 0
      for e in 0..<edgeCount:
        if edges[e].u == nextLo and edges[e].v == nextHi: en = e
        if edges[e].u == prevLo and edges[e].v == prevHi: ep = e
      staged[out] = float64(vertex); inc out
      staged[out] = float64(nv + en); inc out
      staged[out] = float64(nv + edgeCount + f); inc out
      staged[out] = float64(nv + ep); inc out
  if out > MaxOutput: return -1
  if output.isNil or capacity < csize_t(out): return -2
  for i in 0..<out: output[i] = staged[i]
  int64(out)
