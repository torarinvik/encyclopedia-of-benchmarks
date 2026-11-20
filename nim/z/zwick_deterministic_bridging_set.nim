const MaxN = 8
const InfDist = 9'u8

type State = object
  n, threshold: int
  edge, witness, distance: array[64, uint8]
  constraints: array[64, uint16]
  constraintCount: int

proc popcount16(mask: uint16): int =
  var value = mask
  while value != 0:
    result += int(value and 1'u16)
    value = value shr 1

proc subpath(state: var State, fromVertex, toVertex, limit: int,
             output: var array[8, uint8], offset: int): int =
  let encoded = state.witness[fromVertex * state.n + toVertex]
  if limit <= 0 or encoded == 0: return 0
  let middle = int(encoded) - 1
  result = subpath(state, fromVertex, middle, limit - 1, output, offset)
  output[offset + result] = uint8(middle)
  inc result
  let remaining = limit - result
  if remaining > 0:
    result += subpath(state, middle, toVertex, remaining, output, offset + result)

proc solve(input: ptr UncheckedArray[int64], length: csize_t): int64 =
  if input.isNil or length < 2 or length > 131: return -1
  if input[0] < 2 or input[0] > MaxN: return -1
  let n = int(input[0])
  if input[1] < 2 or input[1] > int64(n) or length != csize_t(2 + 2*n*n): return -1
  var state = State(n: n, threshold: int(input[1]))
  let matrix = n*n
  for i in 0 ..< matrix:
    if input[2+i] < 0 or input[2+i] > 1: return -1
    if input[2+matrix+i] < 0 or input[2+matrix+i] > int64(n): return -1
    state.edge[i] = uint8(input[2+i])
    state.witness[i] = uint8(input[2+matrix+i])
  for i in 0 ..< n:
    if state.edge[i*n+i] != 0: return -1
    for j in 0 ..< n:
      state.distance[i*n+j] = if i == j: 0'u8 else: (if state.edge[i*n+j] != 0: 1'u8 else: InfDist)
  for k in 0 ..< n:
    for i in 0 ..< n:
      for j in 0 ..< n:
        let candidate = int(state.distance[i*n+k]) + int(state.distance[k*n+j])
        if candidate < int(state.distance[i*n+j]): state.distance[i*n+j] = uint8(candidate)
  for i in 0 ..< n:
    for j in 0 ..< n:
      let d = int(state.distance[i*n+j])
      let w = int(state.witness[i*n+j])
      if d >= int(InfDist): return -1
      if d <= 1:
        if w != 0: return -1
      else:
        if w == 0: return -1
        let v = w - 1
        if v == i or v == j: return -1
        let left = int(state.distance[i*n+v])
        let right = int(state.distance[v*n+j])
        if left + right != d or left >= d or right >= d: return -1

  for i in 0 ..< n:
    for j in 0 ..< n:
      var internal: array[8, uint8]
      let count = subpath(state, i, j, state.threshold, internal, 0)
      var mask = (1'u16 shl i) or (1'u16 shl j)
      for k in 0 ..< count: mask = mask or (1'u16 shl int(internal[k]))
      if popcount16(mask) >= state.threshold:
        var duplicate = false
        for c in 0 ..< state.constraintCount:
          if state.constraints[c] == mask: duplicate = true
        if not duplicate:
          state.constraints[state.constraintCount] = mask
          inc state.constraintCount
  var unhit: array[64, bool]
  for c in 0 ..< state.constraintCount: unhit[c] = true
  var remaining = state.constraintCount
  var selected = 0'u16
  while remaining > 0:
    var bestVertex = 0
    var bestScore = 0
    for v in 0 ..< n:
      var score = 0
      for c in 0 ..< state.constraintCount:
        if unhit[c] and (state.constraints[c] and (1'u16 shl v)) != 0: inc score
      if score > bestScore:
        bestScore = score
        bestVertex = v
    if bestScore == 0: return -1
    selected = selected or (1'u16 shl bestVertex)
    for c in 0 ..< state.constraintCount:
      if unhit[c] and (state.constraints[c] and (1'u16 shl bestVertex)) != 0:
        unhit[c] = false
        dec remaining
  int64(selected)

proc zwick_deterministic_bridging_set*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "zwick_deterministic_bridging_set".} =
  solve(input, length)
