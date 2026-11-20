const MaxN = 8
const MaxM = 28
const MaxInput = 59
const MaxStates = 256

proc put(outp: ptr UncheckedArray[uint8], at: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: outp[at + byte] = uint8((bits shr (8 * byte)) and 255)

proc biconnected(n, m: int, u, v: array[MaxM, int],
                 active: array[MaxM, bool]): bool =
  for removed in 0..<n:
    let start = if removed == 0: 1 else: 0
    var seen: array[MaxN, bool]
    var queue: array[MaxN, int]
    var head = 0
    var tail = 1
    seen[start] = true
    queue[0] = start
    while head < tail:
      let current = queue[head]
      inc head
      for edge in 0..<m:
        if not active[edge] or u[edge] == removed or v[edge] == removed: continue
        var next = n
        if u[edge] == current: next = v[edge]
        elif v[edge] == current: next = u[edge]
        if next < n and not seen[next]:
          seen[next] = true
          queue[tail] = next
          inc tail
    for vertex in 0..<n:
      if vertex != removed and not seen[vertex]: return false
  true

proc cheriyan_thurimella_two_vertex_connected_augmentation*(
    input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"cheriyan_thurimella_two_vertex_connected_augmentation".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 3 or n0 > 8 or m0 < 3 or m0 > 28: return -1
  let n = int(n0)
  let m = int(m0)
  if int(length) != 2 + 2 * m: return -1
  var u, v: array[MaxM, int]
  for edge in 0..<m:
    let a = input[2 + 2 * edge]
    let b = input[3 + 2 * edge]
    if a < 0 or a >= b or b >= n0: return -1
    u[edge] = int(a)
    v[edge] = int(b)
    for prior in 0..<edge:
      if u[prior] == u[edge] and v[prior] == v[edge]: return -1
  var active: array[MaxM, bool]
  for edge in 0..<m: active[edge] = true
  if not biconnected(n, m, u, v, active): return -1

  let states = 1 shl n
  var best: array[MaxStates, int]
  var choice: array[MaxStates, int]
  for mask in 0..<states: choice[mask] = -1
  for mask in 1..<states:
    var first = 0
    while (mask and (1 shl first)) == 0: inc first
    for edge in 0..<m:
      var other = n
      if u[edge] == first: other = v[edge]
      elif v[edge] == first: other = u[edge]
      if other == n or (mask and (1 shl other)) == 0: continue
      let rest = mask and not (1 shl first) and not (1 shl other)
      let candidate = 1 + best[rest]
      if candidate > best[mask]:
        best[mask] = candidate
        choice[mask] = edge
    let rest = mask and not (1 shl first)
    if best[rest] > best[mask]:
      best[mask] = best[rest]
      choice[mask] = -1

  var cover: array[MaxM, bool]
  var covered: array[MaxN, bool]
  var mask = states - 1
  while mask != 0:
    var first = 0
    while (mask and (1 shl first)) == 0: inc first
    let edge = choice[mask]
    if edge < 0:
      mask = mask and not (1 shl first)
      continue
    cover[edge] = true
    covered[u[edge]] = true
    covered[v[edge]] = true
    mask = mask and not (1 shl u[edge]) and not (1 shl v[edge])
  for vertex in 0..<n:
    if covered[vertex]: continue
    for edge in 0..<m:
      if u[edge] == vertex or v[edge] == vertex:
        cover[edge] = true
        covered[u[edge]] = true
        covered[v[edge]] = true
        break
  for edge in 0..<m:
    if cover[edge]: continue
    active[edge] = false
    if not biconnected(n, m, u, v, active): active[edge] = true
  var count = 0
  for edge in 0..<m:
    if active[edge]: inc count
  let bytes = 8 * (1 + 2 * count)
  if output.isNil or int(capacity) < bytes: return -2
  put(output, 0, int64(count))
  var slot = 0
  for edge in 0..<m:
    if not active[edge]: continue
    put(output, 8 * (1 + 2 * slot), int64(u[edge]))
    put(output, 8 * (2 + 2 * slot), int64(v[edge]))
    inc slot
  int64(bytes)
