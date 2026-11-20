const
  MaxN = 64
  MaxQ = 64
  MaxInput = 323
  Base = 128
  TreeSize = 256

type
  Segment = object
    balance, prefixMin, suffixMax: int64
    minInsert, maxDelete: int64
  RetroQueue = object
    types: array[MaxN + 1, int64]
    values: array[MaxN + 1, int64]
    tree: array[TreeSize, Segment]
    liveCount, liveSum: int64

proc pickMin(q: var RetroQueue, a, b: int64): int64 =
  if a == 0: return b
  if b == 0: return a
  if q.values[int(a)] != q.values[int(b)]:
    return (if q.values[int(a)] < q.values[int(b)]: a else: b)
  max(a, b)

proc pickMax(q: var RetroQueue, a, b: int64): int64 =
  if a == -1: return b
  if b == -1: return a
  if a == 0 or b == 0: return 0
  if q.values[int(a)] != q.values[int(b)]:
    return (if q.values[int(a)] > q.values[int(b)]: a else: b)
  min(a, b)

proc pull(q: var RetroQueue, i: int) =
  var p = (Base + i) div 2
  while p > 0:
    let left = q.tree[2 * p]
    let right = q.tree[2 * p + 1]
    q.tree[p].balance = left.balance + right.balance
    q.tree[p].prefixMin = min(left.prefixMin, left.balance + right.prefixMin)
    q.tree[p].suffixMax = max(left.suffixMax + right.balance, right.suffixMax)
    q.tree[p].minInsert = pickMin(q, left.minInsert, right.minInsert)
    q.tree[p].maxDelete = pickMax(q, left.maxDelete, right.maxDelete)
    p = p div 2

proc nextBridge(q: var RetroQueue, i: int): int =
  var left = Base
  var right = Base + i + 1
  var acc = 0'i64
  while left < right:
    if (left and 1) == 1: acc += q.tree[left].balance; inc left
    if (right and 1) == 1: dec right; acc += q.tree[right].balance
    left = left div 2
    right = right div 2
  if acc == 0: return i + 1
  var node = Base + i + 1
  while true:
    while (node and 1) == 0: node = node div 2
    if acc + q.tree[node].prefixMin == 0:
      while node < Base:
        node *= 2
        if acc + q.tree[node].prefixMin > 0:
          acc += q.tree[node].balance
          inc node
      return node - Base
    acc += q.tree[node].balance
    inc node
    if (node and -node) == node: return Base

proc prevBridge(q: var RetroQueue, i: int): int =
  var left = Base + i
  var right = Base * 2
  var acc = 0'i64
  while left < right:
    if (left and 1) == 1: acc += q.tree[left].balance; inc left
    if (right and 1) == 1: dec right; acc += q.tree[right].balance
    left = left div 2
    right = right div 2
  if acc == 0: return i
  var node = Base + i
  while true:
    dec node
    while node > 1 and (node and 1) == 1: node = node div 2
    if q.tree[node].suffixMax + acc == 0:
      while node < Base:
        node = 2 * node + 1
        if q.tree[node].suffixMax + acc < 0:
          acc += q.tree[node].balance
          dec node
      return node - Base
    acc += q.tree[node].balance
    if (node and -node) == node: return 0

proc findMinInsert(q: var RetroQueue, i: int): int64 =
  var left = Base
  var right = Base + nextBridge(q, i)
  var answer = 0'i64
  while left < right:
    if (left and 1) == 1:
      answer = pickMin(q, answer, q.tree[left].minInsert)
      inc left
    if (right and 1) == 1:
      dec right
      answer = pickMin(q, answer, q.tree[right].minInsert)
    left = left div 2
    right = right div 2
  answer

proc findMaxDelete(q: var RetroQueue, i: int): int64 =
  var left = Base + prevBridge(q, i)
  var right = Base * 2
  var answer = -1'i64
  while left < right:
    if (left and 1) == 1:
      answer = pickMax(q, answer, q.tree[left].maxDelete)
      inc left
    if (right and 1) == 1:
      dec right
      answer = pickMax(q, answer, q.tree[right].maxDelete)
    left = left div 2
    right = right div 2
  answer

proc addOperation(q: var RetroQueue, i: int) =
  let k = findMaxDelete(q, i)
  let leaf = Base + i
  if pickMax(q, i.int64, k) == i.int64:
    q.liveSum += q.values[i]
    inc q.liveCount
    q.tree[leaf].minInsert = i.int64
    pull(q, i)
    return
  q.tree[leaf].maxDelete = i.int64
  q.tree[leaf].balance = 1
  q.tree[leaf].suffixMax = 1
  pull(q, i)
  let mate = Base + int(k)
  if k == 0:
    dec q.tree[mate].balance
    dec q.tree[mate].suffixMax
    if q.tree[mate].balance == 0: q.tree[mate].maxDelete = -1
  else:
    q.liveSum += q.values[int(k)]
    inc q.liveCount
    q.tree[mate].minInsert = k
    q.tree[mate].maxDelete = -1
    q.tree[mate].balance = 0
    q.tree[mate].suffixMax = 0
  pull(q, int(k))

proc removeInsert(q: var RetroQueue, i: int) =
  let leaf = Base + i
  if q.tree[leaf].balance == 0:
    q.liveSum -= q.values[i]
    dec q.liveCount
    q.tree[leaf].minInsert = 0
    pull(q, i)
    return
  let k = findMinInsert(q, i)
  q.tree[leaf].maxDelete = -1
  q.tree[leaf].balance = 0
  q.tree[leaf].suffixMax = 0
  pull(q, i)
  let mate = Base + int(k)
  if k > 0:
    q.liveSum -= q.values[int(k)]
    dec q.liveCount
  q.tree[mate].minInsert = 0
  q.tree[mate].maxDelete = k
  inc q.tree[mate].balance
  inc q.tree[mate].suffixMax
  pull(q, int(k))

proc removeMinimum(q: var RetroQueue, i: int) =
  let k = findMinInsert(q, i)
  let leaf = Base + i
  q.tree[leaf].balance = -1
  q.tree[leaf].prefixMin = -1
  pull(q, i)
  if k > 0:
    q.liveSum -= q.values[int(k)]
    dec q.liveCount
  let mate = Base + int(k)
  q.tree[mate].minInsert = 0
  q.tree[mate].maxDelete = k
  inc q.tree[mate].balance
  inc q.tree[mate].suffixMax
  pull(q, int(k))

proc restoreMinimum(q: var RetroQueue, i: int) =
  let k = findMaxDelete(q, i)
  let leaf = Base + i
  q.tree[leaf].balance = 0
  q.tree[leaf].prefixMin = 0
  pull(q, i)
  let mate = Base + int(k)
  if k == 0:
    dec q.tree[mate].balance
    dec q.tree[mate].suffixMax
    if q.tree[mate].balance == 0: q.tree[mate].maxDelete = -1
  else:
    q.liveSum += q.values[int(k)]
    inc q.liveCount
    q.tree[mate].minInsert = k
    q.tree[mate].maxDelete = -1
    q.tree[mate].balance = 0
    q.tree[mate].suffixMax = 0
  pull(q, int(k))

proc setOperation(q: var RetroQueue, index: int, kind, value: int64) =
  let i = index + 1
  if q.types[i] == 0: removeInsert(q, i)
  elif q.types[i] == 1: restoreMinimum(q, i)
  q.types[i] = kind
  q.values[i] = value
  if kind == 0: addOperation(q, i)
  elif kind == 1: removeMinimum(q, i)

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc partially_retroactive_priority_queue*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "partially_retroactive_priority_queue".} =
  if input == nil or inputLength < 2 or inputLength > csize_t(MaxInput): return -1
  let nValue = input[0]
  let qValue = input[1]
    if nValue < 1 or nValue > int64(MaxN) or qValue < 1 or qValue > int64(MaxQ): return -1
  let n = int(nValue)
  let qn = int(qValue)
  if int(inputLength) != 2 + 2 * n + 3 * qn: return -1
  var at = 2
  for _ in 0 ..< n:
    let kind = input[at]
    let value = input[at + 1]
    at += 2
    if kind == 0:
      if value < 0 or value > 1_000_000: return -1
    elif not ((kind == 1 or kind == 2) and value == -1): return -1
  for _ in 0 ..< qn:
    let index = input[at]
    let kind = input[at + 1]
    let value = input[at + 2]
    at += 3
    if index < 0 or index >= nValue: return -1
    if kind == 0:
      if value < 0 or value > 1_000_000: return -1
    elif not ((kind == 1 or kind == 2) and value == -1): return -1
  let outputSize = 16 * qn
  if output == nil or int(capacity) < outputSize: return -2
  var queue: RetroQueue
  for i in 0 .. MaxN: queue.types[i] = 2; queue.values[i] = -1
  for i in 0 ..< TreeSize: queue.tree[i].maxDelete = -1
  at = 2
  for i in 0 ..< n:
    let kind = input[at]
    let value = input[at + 1]
    at += 2
    setOperation(queue, i, kind, value)
  var written = 0
  for query in 0 ..< qn:
    let index = int(input[at])
    let kind = input[at + 1]
    let value = input[at + 2]
    at += 3
    setOperation(queue, index, kind, value)
    storeI64(output, written, queue.liveCount)
    storeI64(output, written + 8, queue.liveSum)
    written += 16
  int64(written)
