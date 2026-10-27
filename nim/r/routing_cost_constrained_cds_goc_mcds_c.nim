# Clean-room bounded GOC-MCDS-C construction trace.
const MaxN = 8
const MaxInput = 17

proc put64(output: ptr UncheckedArray[uint8], position: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[position + byte] = uint8((bits shr (8 * byte)) and 255)

proc routing_cost_constrained_cds_goc_mcds_c*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "routing_cost_constrained_cds_goc_mcds_c".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput) or input[0] < 1 or input[0] > 8: return -1
  let n = int(input[0])
  if int(length) != 1 + 2 * n: return -1
  let full = (1'u64 shl n) - 1
  var adjacency: array[MaxN, uint64]
  var ids: array[MaxN, int64]
  for v in 0 ..< n:
    let mask = input[1 + v]
    ids[v] = input[1 + n + v]
    if mask < 0 or cast[uint64](mask) > full or (cast[uint64](mask) and (1'u64 shl v)) != 0 or ids[v] < 1 or ids[v] > 1000: return -1
    adjacency[v] = cast[uint64](mask)
    for u in 0 ..< v:
      if ids[u] == ids[v]: return -1
  for u in 0 ..< n:
    for v in 0 ..< n:
      if ((adjacency[u] shr v) and 1) != ((adjacency[v] shr u) and 1): return -1
  var reached = 1'u64
  while true:
    var expanded = reached
    for v in 0 ..< n:
      if ((reached shr v) and 1) != 0: expanded = expanded or adjacency[v]
    if expanded == reached: break
    reached = expanded
  if reached != full: return -1

  var white = full
  var independent = 0'u64
  while white != 0:
    var black = 0'u64
    for v in 0 ..< n:
      if ((white shr v) and 1) == 0: continue
      var lower = false
      for u in 0 ..< n:
        if ((white shr u) and 1) != 0 and ((adjacency[v] shr u) and 1) != 0 and ids[u] < ids[v]: lower = true
      if not lower: black = black or (1'u64 shl v)
    if black == 0: return -1
    independent = independent or black
    var removed = black
    for v in 0 ..< n:
      if ((black shr v) and 1) != 0: removed = removed or adjacency[v]
    white = white and not removed

  var order: array[MaxN, int]
  for i in 0 ..< n:
    order[i] = i
    var j = i
    while j > 0 and ids[order[j - 1]] > ids[order[j]]:
      swap(order[j - 1], order[j])
      dec j
  var connectors = 0'u64
  for a in 0 ..< n:
    let source = order[a]
    if ((independent shr source) and 1) == 0: continue
    for b in (a + 1) ..< n:
      let target = order[b]
      if ((independent shr target) and 1) == 0: continue
      var parent: array[MaxN, int]
      for v in 0 ..< n: parent[v] = -2
      var queue: array[MaxN, int]
      var head = 0
      var tail = 1
      parent[source] = -1
      queue[0] = source
      while head < tail and parent[target] == -2:
        let current = queue[head]
        inc head
        for oi in 0 ..< n:
          let next = order[oi]
          if ((adjacency[current] shr next) and 1) != 0 and parent[next] == -2:
            parent[next] = current
            queue[tail] = next
            inc tail
      if parent[target] == -2: return -1
      var path: array[MaxN, int]
      var pathLength = 0
      var current = target
      while current != source:
        path[pathLength] = current
        inc pathLength
        current = parent[current]
      path[pathLength] = source
      inc pathLength
      if pathLength <= 4:
        for i in 1 ..< (pathLength - 1): connectors = connectors or (1'u64 shl path[i])

  if output.isNil or capacity < csize_t(16): return -2
  put64(addr output[0], 0, cast[int64](independent))
  put64(addr output[0], 8, cast[int64](independent or connectors))
  16
