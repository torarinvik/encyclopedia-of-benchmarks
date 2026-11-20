const MaxN = 16
const MaxQ = 8
const TreeCap = 32
const MaxInput = 43
const MaxOutput = 72

type Interval = object
  low, high: int64
  id: int

proc intervalTreePointStabbing*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "interval_tree_point_stabbing".} =
  if input.isNil or length < 2 or length > MaxInput.csize_t: return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 0 or n64 > MaxN or q64 < 0 or q64 > MaxQ: return -1
  let n = int(n64)
  let q = int(q64)
  if int(length) != 2 + 2 * n + q: return -1
  var sorted: array[MaxN, Interval]
  var cursor = 2
  for ident in 0 ..< n:
    let low = input[cursor]
    let high = input[cursor + 1]
    cursor += 2
    if low < -32 or low > 32 or high < -32 or high > 32 or low > high: return -1
    sorted[ident] = Interval(low: low, high: high, id: ident)
  var points: array[MaxQ, int64]
  for index in 0 ..< q:
    points[index] = input[cursor]
    inc cursor
    if points[index] < -32 or points[index] > 32: return -1
  var index = 1
  while index < n:
    let value = sorted[index]
    var position = index
    while position > 0:
      let previous = sorted[position - 1]
      let greater = previous.low > value.low or
        (previous.low == value.low and previous.high > value.high) or
        (previous.low == value.low and previous.high == value.high and previous.id > value.id)
      if not greater: break
      sorted[position] = previous
      dec position
    sorted[position] = value
    inc index
  var tree: array[TreeCap, Interval]
  var used: array[TreeCap, bool]
  var maximum: array[TreeCap, int64]
  for node in 0 ..< TreeCap: maximum[node] = low(int64)
  if n > 0:
    var firsts, lasts: array[MaxN, int]
    var nodes: array[MaxN, int]
    var top = 1
    firsts[0] = 0; lasts[0] = n - 1; nodes[0] = 0
    while top > 0:
      dec top
      let first = firsts[top]
      let last = lasts[top]
      let node = nodes[top]
      if first > last or node >= TreeCap: continue
      let middle = first + (last - first) div 2
      tree[node] = sorted[middle]
      used[node] = true
      if middle + 1 <= last:
        firsts[top] = middle + 1; lasts[top] = last; nodes[top] = 2 * node + 2; inc top
      if first <= middle - 1:
        firsts[top] = first; lasts[top] = middle - 1; nodes[top] = 2 * node + 1; inc top
  for node in countdown(TreeCap - 1, 0):
    if not used[node]: continue
    maximum[node] = tree[node].high
    let left = 2 * node + 1
    let right = left + 1
    if left < TreeCap and used[left]: maximum[node] = max(maximum[node], maximum[left])
    if right < TreeCap and used[right]: maximum[node] = max(maximum[node], maximum[right])
  var masks: array[MaxQ, int64]
  for qi in 0 ..< q:
    var stack: array[TreeCap, int]
    var top = 0
    if n > 0: stack[top] = 0; inc top
    while top > 0:
      dec top
      let node = stack[top]
      if not used[node] or maximum[node] < points[qi]: continue
      let left = 2 * node + 1
      let right = left + 1
      if left < TreeCap and used[left] and maximum[left] >= points[qi]: stack[top] = left; inc top
      if tree[node].low <= points[qi] and points[qi] <= tree[node].high:
        masks[qi] = masks[qi] or (1'i64 shl tree[node].id)
      if tree[node].low <= points[qi] and right < TreeCap and used[right] and maximum[right] >= points[qi]: stack[top] = right; inc top
  let byteCount = csize_t((q + 1) * 8)
  if output.isNil or capacity < byteCount: return -2
  var staged: array[MaxOutput, uint8]
  let header = uint64(q)
  for byte in 0 ..< 8: staged[byte] = uint8((header shr (8 * byte)) and 255)
  for qi in 0 ..< q:
    let bits = cast[uint64](masks[qi])
    for byte in 0 ..< 8: staged[(qi + 1) * 8 + byte] = uint8((bits shr (8 * byte)) and 255)
  for byte in 0 ..< int(byteCount): output[byte] = staged[byte]
  int64(byteCount)
