proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: output[word * 8 + b] = uint8((bits shr (8 * b)) and 255)

proc sugiyamaBarycenter(order: var array[8, array[32, int]],
    sizes: array[8, int], owner: array[32, int], eu: array[128, int],
    ev: array[128, int], edgeCount, target, fixed: int, downward: bool,
    pos: var array[32, int]) =
  for i in 0 ..< sizes[fixed]: pos[order[fixed][i]] = i
  var rank: array[32, int]
  var numerator: array[32, int64]
  var denominator: array[32, int64]
  for i in 0 ..< sizes[target]: rank[order[target][i]] = i
  for e in 0 ..< edgeCount:
    let u = eu[e]
    let v = ev[e]
    if downward and owner[u] == fixed and owner[v] == target:
      numerator[v] += int64(pos[u])
      denominator[v] += 1
    elif not downward and owner[u] == target and owner[v] == fixed:
      numerator[u] += int64(pos[v])
      denominator[u] += 1
  for i in 0 ..< sizes[target]:
    let v = order[target][i]
    if denominator[v] == 0:
      numerator[v] = int64(rank[v])
      denominator[v] = 1
  for i in 1 ..< sizes[target]:
    let vertex = order[target][i]
    var j = i
    while j > 0:
      let previous = order[target][j - 1]
      let left = numerator[vertex] * denominator[previous]
      let right = numerator[previous] * denominator[vertex]
      if left > right or (left == right and rank[vertex] > rank[previous]): break
      order[target][j] = previous
      dec j
    order[target][j] = vertex
  for i in 0 ..< sizes[target]: pos[order[target][i]] = i

proc sugiyama_barycentric_crossing_reduction*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sugiyama_barycentric_crossing_reduction".} =
  if input.isNil or length < 2 or length > 299: return -1
  let layers0 = input[0]
  let limit0 = input[1]
  if layers0 < 2 or layers0 > 8 or limit0 < 0 or limit0 > 16: return -1
  let layers = int(layers0)
  var order: array[8, array[32, int]]
  var sizes: array[8, int]
  var owner: array[32, int]
  for i in 0 ..< 32: owner[i] = -1
  var pos: array[32, int]
  var eu: array[128, int]
  var ev: array[128, int]
  var at = 2
  var total = 0
  for level in 0 ..< layers:
    if at >= int(length): return -1
    let count0 = input[at]
    inc at
    if count0 < 1 or count0 > 32 or at + int(count0) > int(length): return -1
    sizes[level] = int(count0)
    total += int(count0)
    if total > 32: return -1
    for i in 0 ..< sizes[level]:
      let id0 = input[at]
      inc at
      if id0 < 0 or id0 >= 32 or owner[int(id0)] != -1: return -1
      let id = int(id0)
      order[level][i] = id
      owner[id] = level
  if total < 2 or at >= int(length): return -1
  let edgeCount0 = input[at]
  inc at
  if edgeCount0 < 0 or edgeCount0 > 128 or at + 2 * int(edgeCount0) != int(length): return -1
  let edgeCount = int(edgeCount0)
  for e in 0 ..< edgeCount:
    let u0 = input[at + 2 * e]
    let v0 = input[at + 2 * e + 1]
    if u0 < 0 or u0 >= 32 or v0 < 0 or v0 >= 32: return -1
    let u = int(u0)
    let v = int(v0)
    if owner[u] < 0 or owner[v] != owner[u] + 1: return -1
    for j in 0 ..< e:
      if eu[j] == u and ev[j] == v: return -1
    eu[e] = u
    ev[e] = v
  var sweeps = 0
  for pass in 0 ..< int(limit0):
    let before = order
    for level in 0 ..< layers - 1:
      sugiyamaBarycenter(order, sizes, owner, eu, ev, edgeCount, level + 1, level, true, pos)
    for step in 0 ..< layers - 1:
      let level = layers - 2 - step
      sugiyamaBarycenter(order, sizes, owner, eu, ev, edgeCount, level, level + 1, false, pos)
    inc sweeps
    var changed = false
    for l in 0 ..< layers:
      for i in 0 ..< sizes[l]:
        if before[l][i] != order[l][i]: changed = true
    if not changed: break
  for l in 0 ..< layers:
    for i in 0 ..< sizes[l]: pos[order[l][i]] = i
  var crossings = 0'i64
  for i in 0 ..< edgeCount:
    for j in i + 1 ..< edgeCount:
      if owner[eu[i]] == owner[eu[j]] and
          (pos[eu[i]] - pos[eu[j]]) * (pos[ev[i]] - pos[ev[j]]) < 0:
        inc crossings
  let bytes = 8 * (total + 2)
  if output.isNil or int(capacity) < bytes: return -2
  putI64(output, 0, int64(sweeps))
  putI64(output, 1, crossings)
  var word = 2
  for l in 0 ..< layers:
    for i in 0 ..< sizes[l]:
      putI64(output, word, int64(order[l][i]))
      inc word
  int64(bytes)
