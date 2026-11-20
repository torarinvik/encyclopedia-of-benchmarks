## Dynamic range k-th via a Fenwick tree of mutable weighted value trees.
const MaxN = 12
const MaxQ = 16
const ValueCount = 61
const NodeCapacity = 1280

type TreePool = object
  left: array[NodeCapacity + 1, int]
  right: array[NodeCapacity + 1, int]
  count: array[NodeCapacity + 1, int]
  roots: array[MaxN + 1, int]
  used: int

proc change(pool: var TreePool, rootArg, low, high, coordinate, delta: int): int =
  var root = rootArg
  if root == 0:
    inc pool.used
    root = pool.used
  pool.count[root] += delta
  if high - low > 1:
    let middle = (low + high) div 2
    if coordinate < middle:
      pool.left[root] = change(pool, pool.left[root], low, middle, coordinate, delta)
    else:
      pool.right[root] = change(pool, pool.right[root], middle, high, coordinate, delta)
  root

proc apply(pool: var TreePool, n, position, value, delta: int) =
  var node = position + 1
  while node <= n:
    pool.roots[node] = change(pool, pool.roots[node], 0, ValueCount, value + 30, delta)
    node += node and -node

proc fenwick_weighted_segment_tree_range_kth*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fenwick_weighted_segment_tree_range_kth".} =
  if input.isNil or length < 3 or length > 79: return low(int64)
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return low(int64)
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + n + 4 * q): return low(int64)

  var current: array[MaxN, int]
  var pool: TreePool
  for position in 0 ..< n:
    let value = input[2 + position]
    if value < -30 or value > 30: return low(int64)
    current[position] = int(value)
    pool.apply(n, position, current[position], 1)

  var checksum = 0'i64
  var queryNumber = 0'i64
  var cursor = 2 + n
  for _ in 0 ..< q:
    let opcode = input[cursor]
    let first = input[cursor + 1]
    let second = input[cursor + 2]
    let third = input[cursor + 3]
    cursor += 4
    if opcode == 0:
      if first < 0 or first >= nValue or second < -30 or second > 30 or third != 0: return low(int64)
      let position = int(first)
      pool.apply(n, position, current[position], -1)
      current[position] = int(second)
      pool.apply(n, position, current[position], 1)
    elif opcode == 1:
      if first < 0 or first >= second or second > nValue or third < 1 or third > second - first:
        return low(int64)
      var leftRoots, rightRoots: array[MaxN + 1, int]
      var leftSize = 0
      var rightSize = 0
      var node = int(first)
      while node > 0:
        leftRoots[leftSize] = pool.roots[node]
        inc leftSize
        node -= node and -node
      node = int(second)
      while node > 0:
        rightRoots[rightSize] = pool.roots[node]
        inc rightSize
        node -= node and -node
      var low = 0
      var high = ValueCount
      var rank = int(third)
      while high - low > 1:
        let middle = (low + high) div 2
        var leftCount = 0
        for i in 0 ..< rightSize: leftCount += pool.count[pool.left[rightRoots[i]]]
        for i in 0 ..< leftSize: leftCount -= pool.count[pool.left[leftRoots[i]]]
        if rank <= leftCount:
          for i in 0 ..< rightSize: rightRoots[i] = pool.left[rightRoots[i]]
          for i in 0 ..< leftSize: leftRoots[i] = pool.left[leftRoots[i]]
          high = middle
        else:
          rank -= leftCount
          for i in 0 ..< rightSize: rightRoots[i] = pool.right[rightRoots[i]]
          for i in 0 ..< leftSize: leftRoots[i] = pool.right[leftRoots[i]]
          low = middle
      inc queryNumber
      checksum += queryNumber * int64(low - 30)
    else:
      return low(int64)
  checksum
