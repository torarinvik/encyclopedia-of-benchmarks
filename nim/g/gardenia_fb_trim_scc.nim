## Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile.
const MaxN = 16
const MaxM = 64
const MaxInput = 130
const MaxTasks = 34

proc reach(active: uint32, pivot, n: int, adj: var array[MaxN, array[MaxN, bool]],
    reverse: bool): uint32 =
  var seen = 1'u32 shl pivot
  while true:
    var expanded = seen
    for u in 0 ..< n:
      let ub = 1'u32 shl u
      if (seen and ub) == 0 or (active and ub) == 0: continue
      for v in 0 ..< n:
        let edge = if reverse: adj[v][u] else: adj[u][v]
        if (active and (1'u32 shl v)) != 0 and edge: expanded = expanded or (1'u32 shl v)
    if expanded == seen: return seen
    seen = expanded

proc storeI64LE(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc gardenia_fb_trim_scc*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "gardenia_fb_trim_scc".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64 = input[0]; let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM or
      int64(length) != 2 + 2 * m64: return -1
  let n = int(n64); let m = int(m64)
  var adj: array[MaxN, array[MaxN, bool]]
  for e in 0 ..< m:
    let u64 = input[2 + 2 * e]; let v64 = input[3 + 2 * e]
    if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64: return -1
    let u = int(u64); let v = int(v64)
    if adj[u][v]: return -1
    adj[u][v] = true
  let outputBytes = 8 * n
  if output.isNil or capacity < csize_t(outputBytes): return -2
  var labels: array[MaxN, int64]
  var tasks: array[MaxTasks, uint32]
  var taskCount = 1
  tasks[0] = (1'u32 shl n) - 1
  while taskCount > 0:
    dec taskCount
    var active = tasks[taskCount]
    while active != 0:
      var trimmed = 0'u32
      for u in 0 ..< n:
        let ub = 1'u32 shl u
        if (active and ub) == 0: continue
        var hasIn = false; var hasOut = false
        for v in 0 ..< n:
          if (active and (1'u32 shl v)) == 0: continue
          hasOut = hasOut or adj[u][v]
          hasIn = hasIn or adj[v][u]
        if not hasIn or not hasOut: trimmed = trimmed or ub
      if trimmed == 0: break
      for u in 0 ..< n:
        if (trimmed and (1'u32 shl u)) != 0: labels[u] = int64(u)
      active = active and (not trimmed)
    if active == 0: continue
    var pivot = 0
    while (active and (1'u32 shl pivot)) == 0: inc pivot
    let forward = reach(active, pivot, n, adj, false)
    let backward = reach(active, pivot, n, adj, true)
    let component = forward and backward
    var representative = 0
    while (component and (1'u32 shl representative)) == 0: inc representative
    for u in 0 ..< n:
      if (component and (1'u32 shl u)) != 0: labels[u] = int64(representative)
    let children = [active and (not (forward or backward)), forward and (not backward), backward and (not forward)]
    for child in children:
      if child != 0:
        if taskCount >= MaxTasks: return -1
        tasks[taskCount] = child
        inc taskCount
  for u in 0 ..< n: storeI64LE(output, 8 * u, labels[u])
  int64(outputBytes)
