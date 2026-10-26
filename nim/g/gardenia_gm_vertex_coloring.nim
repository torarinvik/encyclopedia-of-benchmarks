## Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile.
const MaxN = 16
const MaxM = 64
const MaxInput = 130
const MaxColor = 128

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc gardenia_gm_vertex_coloring*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gardenia_gm_vertex_coloring".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64 = input[0]; let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64); let m = int(m64)
  var adjacent: array[MaxN, array[MaxN, bool]]
  for e in 0 ..< m:
    let u64 = input[2 + 2 * e]; let v64 = input[3 + 2 * e]
    if u64 < 0 or v64 <= u64 or v64 >= n64: return -1
    let u = int(u64); let v = int(v64)
    if adjacent[u][v]: return -1
    adjacent[u][v] = true; adjacent[v][u] = true
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var colors: array[MaxN, int]
  var prior: array[MaxN, int]
  var pending: array[MaxN, int]
  var nextPending: array[MaxN, int]
  for u in 0 ..< n: colors[u] = MaxColor; pending[u] = u
  var pendingCount = n
  var rounds = 0
  while pendingCount > 0:
    inc rounds
    if rounds > n + 1: return -1
    prior = colors
    for item in 0 ..< pendingCount:
      let u = pending[item]
      var forbidden: array[MaxN, bool]
      for v in 0 ..< n:
        if adjacent[u][v] and prior[v] != MaxColor: forbidden[prior[v]] = true
      var color = 0
      while color < MaxColor and forbidden[color]: inc color
      if color >= MaxColor: return -1
      colors[u] = color
    var nextCount = 0
    for item in 0 ..< pendingCount:
      let u = pending[item]
      var conflict = false
      for v in u + 1 ..< n:
        if adjacent[u][v] and colors[u] == colors[v]: conflict = true; break
      if conflict:
        colors[u] = MaxColor
        nextPending[nextCount] = u
        inc nextCount
    pendingCount = nextCount
    for item in 0 ..< pendingCount: pending[item] = nextPending[item]
  for u in 0 ..< n: storeI64LE(output, 8 * u, int64(colors[u]))
  int64(outputBytes)
