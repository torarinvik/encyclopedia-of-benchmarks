## Clean-room bounded Kanj--Perkovic modified-Yao selection pass.
const
  N = 16
  M = 42
  K = 14
  D = 84
  MaxValid = 312
  MaxParseable = 313

proc kanj_perkovic_modified_yao_spanner(input: ptr int64; length: csize_t): int64 {.exportc, cdecl.} =
  if input == nil or length < 2 or length > MaxParseable.csize_t: return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 3 or n64 > N.int64 or m64 < n64 - 1 or m64 > M.int64 or m64 > 3 * n64 - 6: return -1
  let n = n64.int
  let m = m64.int
  let dcount = 2 * m
  if length != (2 + n + 7 * m).csize_t or length > MaxValid.csize_t: return -1

  var edgeU: array[M, int]
  var edgeV: array[M, int]
  var weight: array[M, int64]
  var adjacent: array[N, array[N, bool]]
  var expectedDegree: array[N, int]
  var source: array[D, int]
  var cone: array[D, int]
  for e in 0 ..< m:
    let p = 2 + 5 * e
    let u64 = input[p]
    let v64 = input[p + 1]
    let w = input[p + 2]
    let cu64 = input[p + 3]
    let cv64 = input[p + 4]
    if u64 < 0 or u64 >= v64 or v64 >= n64 or w < 1 or w > 1_000_000_000_000'i64 or cu64 < 0 or cu64 >= K.int64 or cv64 < 0 or cv64 >= K.int64: return -1
    let u = u64.int
    let v = v64.int
    if e > 0 and (u < edgeU[e - 1] or (u == edgeU[e - 1] and v <= edgeV[e - 1])): return -1
    let cu = cu64.int
    let cv = cv64.int
    edgeU[e] = u; edgeV[e] = v; weight[e] = w
    adjacent[u][v] = true; adjacent[v][u] = true
    inc expectedDegree[u]; inc expectedDegree[v]
    source[2 * e] = u; source[2 * e + 1] = v
    cone[2 * e] = cu; cone[2 * e + 1] = cv

  var rotation: array[D, int]
  var position: array[D, int]
  var rowStart: array[N, int]
  var degree: array[N, int]
  var first: array[N, array[K, int]]
  var after: array[N, array[K, int]]
  var seen: array[D, bool]
  for v in 0 ..< N:
    for c in 0 ..< K:
      first[v][c] = -1
      after[v][c] = -1
  var cursor = 2 + 5 * m
  var used = 0
  for v in 0 ..< n:
    let d64 = input[cursor]
    inc cursor
    if d64 < 1 or d64.int != expectedDegree[v] or d64 > D.int64: return -1
    let d = d64.int
    rowStart[v] = used; degree[v] = d
    var previous = -1
    for _ in 0 ..< d:
      let raw = input[cursor]
      inc cursor
      if raw < 0 or raw >= dcount.int64: return -1
      let dart = raw.int
      let c = cone[dart]
      if seen[dart] or source[dart] != v or c < previous: return -1
      previous = c; seen[dart] = true; rotation[used] = dart; position[dart] = used
      if first[v][c] < 0: first[v][c] = used
      after[v][c] = used + 1
      inc used
  if cursor != length.int or used != dcount: return -1
  for dart in 0 ..< dcount:
    if not seen[dart]: return -1

  var reached: array[N, bool]
  var queue: array[N, int]
  var head = 0
  var tail = 1
  queue[0] = 0; reached[0] = true
  while head < tail:
    let u = queue[head]; inc head
    for v in 0 ..< n:
      if adjacent[u][v] and not reached[v]:
        reached[v] = true; queue[tail] = v; inc tail
  if tail != n: return -1

  var nextFace: array[D, int]
  var faceSeen: array[D, bool]
  var faces = 0
  for dart in 0 ..< dcount:
    let twin = dart xor 1
    let dest = source[twin]
    let local = position[twin] - rowStart[dest]
    nextFace[dart] = rotation[rowStart[dest] + (local + degree[dest] - 1) mod degree[dest]]
  for dart in 0 ..< dcount:
    if not faceSeen[dart]:
      inc faces
      var current = dart
      while not faceSeen[current]:
        faceSeen[current] = true
        current = nextFace[current]
      if current != dart: return -1
  if n - m + faces != 2: return -1

  var selected: array[D, bool]
  for v in 0 ..< n:
    for c in 0 ..< K:
      if first[v][c] < 0: continue
      var best = -1
      for p in first[v][c] ..< after[v][c]:
        let dart = rotation[p]
        let e = dart div 2
        if best < 0 or weight[e] < weight[best div 2] or (weight[e] == weight[best div 2] and e < best div 2): best = dart
      selected[best] = true

  for v in 0 ..< n:
    var occupied = false
    for c in 0 ..< K: occupied = occupied or first[v][c] >= 0
    if not occupied: continue
    for start in 0 ..< K:
      if first[v][start] >= 0 or first[v][(start + K - 1) mod K] < 0: continue
      var run = 0
      while run < K and first[v][(start + run) mod K] < 0: inc run
      if run == 1:
        let cwCone = (start + K - 1) mod K
        let ccwCone = (start + 1) mod K
        let cw = rotation[after[v][cwCone] - 1]
        let ccw = rotation[first[v][ccwCone]]
        if selected[cw]: selected[ccw] = true
        elif selected[ccw]: selected[cw] = true
        else:
          let a = cw div 2
          let b = ccw div 2
          if weight[a] < weight[b] or (weight[a] == weight[b] and a < b): selected[cw] = true
          else: selected[ccw] = true
      else:
        var cwLeft = run div 2
        var ccwLeft = (run + 1) div 2
        for step in 1 .. K:
          if cwLeft == 0: break
          let c = (start - step + K) mod K
          if first[v][c] >= 0:
            for p in countdown(after[v][c] - 1, first[v][c]):
              if cwLeft == 0: break
              let dart = rotation[p]
              if not selected[dart]: selected[dart] = true; dec cwLeft
        for step in run ..< run + K:
          if ccwLeft == 0: break
          let c = (start + step) mod K
          if first[v][c] >= 0:
            for p in first[v][c] ..< after[v][c]:
              if ccwLeft == 0: break
              let dart = rotation[p]
              if not selected[dart]: selected[dart] = true; dec ccwLeft

  var mask = 0'u64
  for e in 0 ..< m:
    if selected[2 * e] and selected[2 * e + 1]: mask = mask or (1'u64 shl e)
  result = cast[int64](mask)
