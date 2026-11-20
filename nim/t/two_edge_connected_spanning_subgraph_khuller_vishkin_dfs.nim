const MaxN = 8
const MaxM = 28
const MaxInput = 59

proc put(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for i in 0..<8: outp[at + i] = uint8((bits shr (8 * i)) and 255)

proc connected(n, m: int, u, v: array[MaxM, int], skip: int): bool =
  var seen: array[MaxN, bool]
  var queue: array[MaxN, int]
  var head = 0
  var tail = 1
  queue[0] = 0
  seen[0] = true
  while head < tail:
    let x = queue[head]
    inc head
    for e in 0..<m:
      if e == skip: continue
      var y = MaxN
      if u[e] == x: y = v[e]
      elif v[e] == x: y = u[e]
      if y < n and not seen[y]:
        seen[y] = true
        queue[tail] = y
        inc tail
  for i in 0..<n:
    if not seen[i]: return false
  true

proc two_edge_connected_spanning_subgraph_khuller_vishkin_dfs*(
    input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"two_edge_connected_spanning_subgraph_khuller_vishkin_dfs".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 3 or n0 > 8 or m0 < 3 or m0 > 28 or int(length) != 2 + 2 * int(m0): return -1
  let n = int(n0)
  let m = int(m0)
  var u, v: array[MaxM, int]
  for e in 0..<m:
    let a = input[2 + 2 * e]
    let b = input[3 + 2 * e]
    if a < 0 or a >= b or b >= n0: return -1
    u[e] = int(a)
    v[e] = int(b)
    for j in 0..<e:
      if u[j] == u[e] and v[j] == v[e]: return -1
  if not connected(n, m, u, v, -1): return -1
  for e in 0..<m:
    if not connected(n, m, u, v, e): return -1

  var state, disc, low, lowH, savior: array[MaxN, int]
  var selected: array[MaxM, bool]
  var stackV, stackParent, stackCursor: array[MaxN, int]
  var tick = 1
  var top = 1
  state[0] = 1
  disc[0] = 0
  low[0] = 0
  lowH[0] = 0
  savior[0] = 0
  stackV[0] = 0
  stackParent[0] = MaxN
  stackCursor[0] = 0
  while top > 0:
    let frame = top - 1
    let x = stackV[frame]
    let parent = stackParent[frame]
    if stackCursor[frame] < m:
      let e = stackCursor[frame]
      inc stackCursor[frame]
      var y = MaxN
      if u[e] == x: y = v[e]
      elif v[e] == x: y = u[e]
      if y == MaxN: continue
      if state[y] == 0:
        selected[e] = true
        state[y] = 1
        disc[y] = tick
        inc tick
        low[y] = y
        lowH[y] = y
        savior[y] = y
        stackV[top] = y
        stackParent[top] = x
        stackCursor[top] = 0
        inc top
      elif state[y] == 1 and y != parent and disc[y] < disc[low[x]]:
        low[x] = y
        savior[x] = x
      continue
    state[x] = 2
    if parent < n and lowH[x] == x:
      let lo = min(savior[x], low[x])
      let hi = max(savior[x], low[x])
      for e in 0..<m:
        if u[e] == lo and v[e] == hi:
          selected[e] = true
          break
      lowH[x] = low[x]
    dec top
    if parent < n:
      if disc[low[x]] < disc[low[parent]]:
        low[parent] = low[x]
        savior[parent] = savior[x]
      if disc[lowH[x]] < disc[lowH[parent]]: lowH[parent] = lowH[x]

  var count = 0
  for e in 0..<m:
    if selected[e]: inc count
  let bytes = 8 * (1 + 2 * count)
  if output.isNil or int(capacity) < bytes: return -2
  put(output, 0, int64(count))
  var at = 8
  for a in 0..<n:
    for b in (a + 1)..<n:
      for e in 0..<m:
        if selected[e] and u[e] == a and v[e] == b:
          put(output, at, int64(a))
          put(output, at + 8, int64(b))
          at += 16
  int64(bytes)
