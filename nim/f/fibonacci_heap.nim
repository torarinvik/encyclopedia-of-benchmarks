## Insert keys into a bounded Fibonacci heap and emit repeated extract-min results.
const MaxNodes = 128
type FibNode = object
  key: int64
  parent, child, left, right, degree: int

proc fibonacci_heap*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "fibonacci_heap".} =
  if (values == nil and length > 0) or length > MaxNodes.csize_t: return -1
  let n = int(length)
  for i in 0 ..< n:
    if values[i] < -2_147_483_648'i64 or values[i] > 2_147_483_647'i64: return -1
  if outputCapacity < length * 8 or (n > 0 and output == nil): return -2
  var nodes: array[MaxNodes, FibNode]
  var minimum = -1
  proc addRoot(x: int) =
    nodes[x].parent = -1
    if minimum < 0:
      nodes[x].left = x; nodes[x].right = x; minimum = x
    else:
      let r = nodes[minimum].right
      nodes[x].left = minimum; nodes[x].right = r
      nodes[minimum].right = x; nodes[r].left = x
      if nodes[x].key < nodes[minimum].key: minimum = x
  proc unlink(x: int) =
    nodes[nodes[x].left].right = nodes[x].right
    nodes[nodes[x].right].left = nodes[x].left
  proc link(parent, child: int) =
    nodes[child].parent = parent
    if nodes[parent].child < 0:
      nodes[parent].child = child; nodes[child].left = child; nodes[child].right = child
    else:
      let c = nodes[parent].child
      let r = nodes[c].right
      nodes[child].left = c; nodes[child].right = r
      nodes[c].right = child; nodes[r].left = child
    inc nodes[parent].degree
  for i in 0 ..< n:
    nodes[i] = FibNode(key: values[i], parent: -1, child: -1, left: i, right: i)
    addRoot(i)
  var emitted = 0
  while minimum >= 0:
    let z = minimum
    let key = nodes[z].key
    if nodes[z].child >= 0:
      var kids: array[MaxNodes, int]
      var count = 0
      let start = nodes[z].child
      var c = start
      while true:
        kids[count] = c; inc count
        c = nodes[c].right
        if c == start: break
      for j in 0 ..< count:
        unlink(kids[j]); addRoot(kids[j])
      nodes[z].child = -1; nodes[z].degree = 0
    let single = nodes[z].right == z
    unlink(z)
    minimum = if single: -1 else: nodes[z].right
    if minimum >= 0:
      var roots: array[MaxNodes, int]
      var rootCount = 0
      let start = minimum
      var x = start
      while true:
        roots[rootCount] = x; inc rootCount
        x = nodes[x].right
        if x == start: break
      var table: array[MaxNodes, int]
      for i in 0 ..< MaxNodes: table[i] = -1
      for ri in 0 ..< rootCount:
        x = roots[ri]
        if nodes[x].parent >= 0: continue
        var d = nodes[x].degree
        while table[d] >= 0:
          var y = table[d]
          if nodes[y].key < nodes[x].key: swap(x, y)
          unlink(y); link(x, y); table[d] = -1; d = nodes[x].degree
        table[d] = x
      minimum = -1
      for i in 0 ..< MaxNodes:
        if table[i] >= 0:
          nodes[table[i]].left = table[i]; nodes[table[i]].right = table[i]
          addRoot(table[i])
    let bits = cast[uint64](key)
    for b in 0 ..< 8: output[emitted * 8 + b] = uint8((bits shr (b * 8)) and 255)
    inc emitted
  int64(emitted * 8)
