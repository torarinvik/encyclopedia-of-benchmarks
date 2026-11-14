type Tree = object
  minimum, lazy: array[256, int64]

proc build(t: var Tree, input: ptr UncheckedArray[int64], node, left, right: int) =
  if right - left == 1:
    t.minimum[node] = input[2 + left]
    return
  let middle = (left + right) div 2
  t.build(input, 2 * node, left, middle)
  t.build(input, 2 * node + 1, middle, right)
  t.minimum[node] = min(t.minimum[2 * node], t.minimum[2 * node + 1])

proc push(t: var Tree, node: int) =
  for child in 2 * node .. 2 * node + 1:
    t.minimum[child] += t.lazy[node]
    t.lazy[child] += t.lazy[node]
  t.lazy[node] = 0

proc add(t: var Tree, node, left, right, first, last: int, delta: int64) =
  if last <= left or right <= first: return
  if first <= left and right <= last:
    t.minimum[node] += delta
    t.lazy[node] += delta
    return
  t.push(node)
  let middle = (left + right) div 2
  t.add(2 * node, left, middle, first, last, delta)
  t.add(2 * node + 1, middle, right, first, last, delta)
  t.minimum[node] = min(t.minimum[2 * node], t.minimum[2 * node + 1])

proc query(t: var Tree, node, left, right, first, last: int): int64 =
  if last <= left or right <= first: return high(int64)
  if first <= left and right <= last: return t.minimum[node]
  t.push(node)
  let middle = (left + right) div 2
  let a = t.query(2 * node, left, middle, first, last)
  let b = t.query(2 * node + 1, middle, right, first, last)
  min(a, b)

proc range_add_range_min*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 2 or length > 322 or
      input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64: return -1
  let n = int(input[0])
  let q = int(input[1])
  if length != csize_t(2 + n + 4 * q): return -1
  for i in 0 ..< n:
    if input[2 + i] < -1_000_000 or input[2 + i] > 1_000_000: return -1
  var queries = 0
  for i in 0 ..< q:
    let base = 2 + n + 4 * i
    let op = input[base]
    let left = input[base + 1]
    let right = input[base + 2]
    let delta = input[base + 3]
    if left < 0 or left >= right or right > int64(n): return -1
    if op == 0:
      if delta < -100_000 or delta > 100_000: return -1
    elif op == 1:
      if delta != 0: return -1
      inc queries
    else: return -1
  if queries == 0: return -1
  if output == nil or capacity < csize_t(8 * queries): return -2
  var tree: Tree
  tree.build(input, 1, 0, n)
  var written = 0
  for i in 0 ..< q:
    let base = 2 + n + 4 * i
    let left = int(input[base + 1])
    let right = int(input[base + 2])
    if input[base] == 0:
      tree.add(1, 0, n, left, right, input[base + 3])
    else:
      let bits = cast[uint64](tree.query(1, 0, n, left, right))
      for byte in 0 ..< 8:
        output[8 * written + byte] = uint8((bits shr (8 * byte)) and 255'u64)
      inc written
  int64(8 * written)
