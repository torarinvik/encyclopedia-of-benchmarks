const
  QMAX = 32
  ROOTS = 65
  ARENA = 16384
  POOL = 8192
  LEVELS = 16
  MAX_INPUT = 194
  MAX_PARSEABLE = 195
  MAX_OUTPUT = 1792
  NODE_BASE = 8192'i32
  VMAX = 1_000_000'i64
  SUMMAX = 64_000_000'i64

type
  Measure = object
    count: int32
    sum: int64
  Tree = object
    kind, level, plen, slen: uint8
    mid: int32
    pre, suf: array[4, int32]
    count: int32
    sum: int64
  Node = object
    arity: uint8
    child: array[3, int32]
    count: int32
    sum: int64
  Root = object
    tree, length: int32
    sum: int64
  View = object
    found: bool
    item, tree: int32
  Split = object
    found: bool
    item, left, right: int32
  Context = object
    trees: array[POOL, Tree]
    nodes: array[POOL, Node]
    nt, nn: int
    empty: array[LEVELS, int32]
    ready: array[LEVELS, bool]
    failed: bool

proc add(a, b: Measure): Measure = Measure(count: a.count + b.count, sum: a.sum + b.sum)
proc treeMeasure(c: var Context, id: int32): Measure =
  let t = c.trees[int(id)]
  Measure(count: t.count, sum: t.sum)
proc refMeasure(c: var Context, r: int32): Measure =
  if r < 0: return Measure(count: 1, sum: -int64(r) - 1)
  let n = c.nodes[int(r - NODE_BASE)]
  Measure(count: n.count, sum: n.sum)
proc allocTree(c: var Context): int32 =
  if c.nt + c.nn >= ARENA or c.nt >= POOL:
    c.failed = true
    return 0
  result = int32(c.nt)
  inc c.nt
proc allocNode(c: var Context): int32 =
  if c.nt + c.nn >= ARENA or c.nn >= POOL:
    c.failed = true
    return NODE_BASE
  result = NODE_BASE + int32(c.nn)
  inc c.nn
proc emptyTree(c: var Context, level: int): int32 =
  if level < 0 or level >= LEVELS:
    c.failed = true
    return 0
  if c.ready[level]: return c.empty[level]
  let id = allocTree(c)
  c.trees[int(id)] = Tree(kind: 0, level: uint8(level), mid: -1)
  c.empty[level] = id
  c.ready[level] = true
  id
proc makeSingle(c: var Context, level: int, item: int32): int32 =
  let id = allocTree(c)
  let m = refMeasure(c, item)
  c.trees[int(id)] = Tree(kind: 1, level: uint8(level), plen: 1, pre: [item, 0'i32, 0'i32, 0'i32], count: m.count, sum: m.sum)
  id
proc makeNode(c: var Context, level: int, items: openArray[int32]): int32 =
  let id = allocNode(c)
  var n = Node(arity: uint8(items.len))
  var m = Measure()
  for i, item in items:
    n.child[i] = item
    m = add(m, refMeasure(c, item))
  n.count = m.count
  n.sum = m.sum
  c.nodes[int(id - NODE_BASE)] = n
  id
proc makeDeep(c: var Context, level: int, pre: openArray[int32], mid: int32, suf: openArray[int32]): int32 =
  if pre.len == 0 or suf.len == 0:
    c.failed = true
    return emptyTree(c, level)
  let id = allocTree(c)
  var t = Tree(kind: 2, level: uint8(level), plen: uint8(pre.len), slen: uint8(suf.len), mid: mid)
  var m = treeMeasure(c, mid)
  for i, item in pre:
    t.pre[i] = item
    m = add(m, refMeasure(c, item))
  for i, item in suf:
    t.suf[i] = item
    m = add(m, refMeasure(c, item))
  t.count = m.count
  t.sum = m.sum
  c.trees[int(id)] = t
  id

proc cons(c: var Context, level: int, item: int32, id: int32): int32
proc snoc(c: var Context, level: int, id: int32, item: int32): int32
proc fromItems(c: var Context, level: int, items: openArray[int32]): int32 =
  result = emptyTree(c, level)
  for item in items: result = snoc(c, level, result, item)
proc cons(c: var Context, level: int, item: int32, id: int32): int32 =
  let t = c.trees[int(id)]
  if t.kind == 0: return makeSingle(c, level, item)
  if t.kind == 1: return makeDeep(c, level, [item], emptyTree(c, level + 1), [t.pre[0]])
  if t.plen < 4:
    var pre: array[4, int32]
    pre[0] = item
    for i in 0 ..< int(t.plen): pre[i + 1] = t.pre[i]
    return makeDeep(c, level, pre.toOpenArray(0, int(t.plen)), t.mid, t.suf.toOpenArray(0, int(t.slen)-1))
  let middle = cons(c, level + 1, makeNode(c, level, [t.pre[1], t.pre[2], t.pre[3]]), t.mid)
  makeDeep(c, level, [item, t.pre[0]], middle, t.suf.toOpenArray(0, int(t.slen)-1))
proc snoc(c: var Context, level: int, id: int32, item: int32): int32 =
  let t = c.trees[int(id)]
  if t.kind == 0: return makeSingle(c, level, item)
  if t.kind == 1: return makeDeep(c, level, [t.pre[0]], emptyTree(c, level + 1), [item])
  if t.slen < 4:
    var suf = t.suf
    suf[int(t.slen)] = item
    return makeDeep(c, level, t.pre.toOpenArray(0, int(t.plen)-1), t.mid, suf.toOpenArray(0, int(t.slen)))
  let middle = snoc(c, level + 1, t.mid, makeNode(c, level, [t.suf[0], t.suf[1], t.suf[2]]))
  makeDeep(c, level, t.pre.toOpenArray(0, int(t.plen)-1), middle, [t.suf[3], item])
proc viewLeft(c: var Context, level: int, id: int32): View =
  let t = c.trees[int(id)]
  if t.kind == 0: return View(found: false, tree: id)
  if t.kind == 1: return View(found: true, item: t.pre[0], tree: emptyTree(c, level))
  let item = t.pre[0]
  var rest: int32
  if t.plen > 1:
    rest = makeDeep(c, level, t.pre.toOpenArray(1, int(t.plen)-1), t.mid, t.suf.toOpenArray(0, int(t.slen)-1))
  else:
    let mv = viewLeft(c, level + 1, t.mid)
    if not mv.found:
      rest = fromItems(c, level, t.suf.toOpenArray(0, int(t.slen)-1))
    else:
      let n = c.nodes[int(mv.item - NODE_BASE)]
      rest = makeDeep(c, level, n.child.toOpenArray(0, int(n.arity)-1), mv.tree, t.suf.toOpenArray(0, int(t.slen)-1))
  View(found: true, item: item, tree: rest)
proc viewRight(c: var Context, level: int, id: int32): View =
  let t = c.trees[int(id)]
  if t.kind == 0: return View(found: false, tree: id)
  if t.kind == 1: return View(found: true, item: t.pre[0], tree: emptyTree(c, level))
  let item = t.suf[int(t.slen)-1]
  var rest: int32
  if t.slen > 1:
    rest = makeDeep(c, level, t.pre.toOpenArray(0, int(t.plen)-1), t.mid, t.suf.toOpenArray(0, int(t.slen)-2))
  else:
    let mv = viewRight(c, level + 1, t.mid)
    if not mv.found:
      rest = fromItems(c, level, t.pre.toOpenArray(0, int(t.plen)-1))
    else:
      let n = c.nodes[int(mv.item - NODE_BASE)]
      rest = makeDeep(c, level, t.pre.toOpenArray(0, int(t.plen)-1), mv.tree, n.child.toOpenArray(0, int(n.arity)-1))
  View(found: true, item: item, tree: rest)
proc deepLeft(c: var Context, level: int, pre: openArray[int32], mid: int32, suf: openArray[int32]): int32 =
  if pre.len > 0: return makeDeep(c, level, pre, mid, suf)
  let v = viewLeft(c, level + 1, mid)
  if not v.found: return fromItems(c, level, suf)
  let n = c.nodes[int(v.item - NODE_BASE)]
  makeDeep(c, level, n.child.toOpenArray(0, int(n.arity)-1), v.tree, suf)
proc deepRight(c: var Context, level: int, pre: openArray[int32], mid: int32, suf: openArray[int32]): int32 =
  if suf.len > 0: return makeDeep(c, level, pre, mid, suf)
  let v = viewRight(c, level + 1, mid)
  if not v.found: return fromItems(c, level, pre)
  let n = c.nodes[int(v.item - NODE_BASE)]
  makeDeep(c, level, pre, v.tree, n.child.toOpenArray(0, int(n.arity)-1))
proc groupItems(c: var Context, level: int, items: openArray[int32]): seq[int32] =
  var pos = 0
  while pos < items.len:
    let rem = items.len - pos
    let take = if rem == 2 or rem == 4: 2 else: 3
    if rem == 1:
      c.failed = true
      return
    result.add(makeNode(c, level, items.toOpenArray(pos, pos + take - 1)))
    pos += take
proc append3(c: var Context, level: int, left: int32, bridge: openArray[int32], right: int32): int32 =
  let a = c.trees[int(left)]
  let b = c.trees[int(right)]
  if a.kind == 0:
    result = right
    for i in countdown(bridge.len-1, 0): result = cons(c, level, bridge[i], result)
    return
  if b.kind == 0:
    result = left
    for item in bridge: result = snoc(c, level, result, item)
    return
  if a.kind == 1:
    result = right
    for i in countdown(bridge.len-1, 0): result = cons(c, level, bridge[i], result)
    return cons(c, level, a.pre[0], result)
  if b.kind == 1:
    result = left
    for item in bridge: result = snoc(c, level, result, item)
    return snoc(c, level, result, b.pre[0])
  var middleItems: seq[int32]
  for i in 0 ..< int(a.slen): middleItems.add(a.suf[i])
  for item in bridge: middleItems.add(item)
  for i in 0 ..< int(b.plen): middleItems.add(b.pre[i])
  let grouped = groupItems(c, level, middleItems)
  let middle = append3(c, level + 1, a.mid, grouped, b.mid)
  makeDeep(c, level, a.pre.toOpenArray(0, int(a.plen)-1), middle, b.suf.toOpenArray(0, int(b.slen)-1))
proc predicate(mode: int, target: int64, m: Measure): bool =
  if mode == 0: return int64(m.count) > target
  m.sum >= target
proc splitTree(c: var Context, id: int32, acc: Measure, mode: int, target: int64): Split =
  let t = c.trees[int(id)]
  if t.kind == 0: return Split(found: false, left: id, right: emptyTree(c, int(t.level)))
  if t.kind == 1:
    if predicate(mode, target, add(acc, refMeasure(c, t.pre[0]))):
      let e = emptyTree(c, int(t.level))
      return Split(found: true, item: t.pre[0], left: e, right: e)
    return Split(found: false, left: id, right: emptyTree(c, int(t.level)))
  var cur = acc
  for i in 0 ..< int(t.plen):
    cur = add(cur, refMeasure(c, t.pre[i]))
    if predicate(mode, target, cur):
      let left = fromItems(c, int(t.level), t.pre.toOpenArray(0, i-1))
      let right = deepLeft(c, int(t.level), t.pre.toOpenArray(i+1, int(t.plen)-1), t.mid, t.suf.toOpenArray(0, int(t.slen)-1))
      return Split(found: true, item: t.pre[i], left: left, right: right)
  var prefix = acc
  for i in 0 ..< int(t.plen): prefix = add(prefix, refMeasure(c, t.pre[i]))
  let through = add(prefix, treeMeasure(c, t.mid))
  if predicate(mode, target, through):
    let sm = splitTree(c, t.mid, prefix, mode, target)
    if not sm.found:
      c.failed = true
      return Split(found: false, left: id, right: emptyTree(c, int(t.level)))
    let nd = c.nodes[int(sm.item - NODE_BASE)]
    var ca = add(prefix, treeMeasure(c, sm.left))
    var before, after: seq[int32]
    var pivot = 0'i32
    var found = false
    for i in 0 ..< int(nd.arity):
      let item = nd.child[i]
      let next = add(ca, refMeasure(c, item))
      if not found and predicate(mode, target, next):
        pivot = item
        found = true
      elif not found:
        before.add(item)
        ca = next
      else:
        after.add(item)
    if not found:
      c.failed = true
      return Split(found: false, left: id, right: emptyTree(c, int(t.level)))
    let left = deepRight(c, int(t.level), t.pre.toOpenArray(0, int(t.plen)-1), sm.left, before)
    let right = deepLeft(c, int(t.level), after, sm.right, t.suf.toOpenArray(0, int(t.slen)-1))
    return Split(found: true, item: pivot, left: left, right: right)
  cur = through
  var before: seq[int32]
  for i in 0 ..< int(t.slen):
    cur = add(cur, refMeasure(c, t.suf[i]))
    if predicate(mode, target, cur):
      let left = deepRight(c, int(t.level), t.pre.toOpenArray(0, int(t.plen)-1), t.mid, before)
      let right = fromItems(c, int(t.level), t.suf.toOpenArray(i+1, int(t.slen)-1))
      return Split(found: true, item: t.suf[i], left: left, right: right)
    before.add(t.suf[i])
  Split(found: false, left: id, right: emptyTree(c, int(t.level)))

proc put64(outp: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[offset+b] = uint8((bits shr (8*b)) and 255)

proc measured_finger_tree_sequence_impl(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 =
  if input == nil or length < 2 or length > MAX_PARSEABLE: return -1
  let n64 = input[0]
  if n64 < 0 or n64 > 32: return -1
  let n = int(n64)
  if length < csize_t(n + 2): return -1
  let q64 = input[n+1]
  if q64 < 1 or q64 > 32: return -1
  let q = int(q64)
  if length != csize_t(n+2+5*q) or length > MAX_INPUT: return -1
  var c: Context
  for i in 0 ..< LEVELS: c.empty[i] = -1
  var tree = emptyTree(c, 0)
  for i in 0 ..< n:
    let x = input[1+i]
    if x < 0 or x > VMAX: return -1
    tree = snoc(c, 0, tree, int32(-x-1))
  if c.failed: return -1
  let initial = treeMeasure(c, tree)
  if initial.count > 64 or initial.sum > SUMMAX: return -1
  var roots: array[ROOTS, Root]
  roots[0] = Root(tree: tree, length: initial.count, sum: initial.sum)
  var nr = 1
  var cursor = n+2
  var records: array[QMAX*7, int64]
  for op in 0 ..< q:
    let tag = input[cursor]
    let aa = input[cursor+1]
    let bb = input[cursor+2]
    let x = input[cursor+3]
    let y = input[cursor+4]
    cursor += 5
    if tag < 0 or tag > 6 or aa < 0 or aa >= int64(nr) or nr >= ROOTS: return -1
    let a = int(aa)
    let source = roots[a].tree
    var result, result2: int32
    var rightRoot = -1'i32
    var aux = -1'i64
    var two = false
    if tag <= 1:
      if bb != -1 or y != -1 or x < 0 or x > VMAX or roots[a].length >= 64 or roots[a].sum + x > SUMMAX: return -1
      let item = int32(-x-1)
      result = if tag == 0: cons(c, 0, item, source) else: snoc(c, 0, source, item)
    elif tag <= 3:
      if bb != -1 or x != -1 or y != -1 or roots[a].length == 0: return -1
      let v = if tag == 2: viewLeft(c, 0, source) else: viewRight(c, 0, source)
      if not v.found: return -1
      result = v.tree
      aux = -int64(v.item)-1
    elif tag == 4:
      if bb < 0 or bb >= int64(nr) or x != -1 or y != -1: return -1
      let b = int(bb)
      if roots[a].length + roots[b].length > 64 or roots[a].sum + roots[b].sum > SUMMAX: return -1
      result = append3(c, 0, source, [], roots[b].tree)
    else:
      if bb != -1 or y != -1 or (tag == 5 and (x < 0 or x > int64(roots[a].length))) or (tag == 6 and (x < 1 or x > SUMMAX)): return -1
      let s = splitTree(c, source, Measure(), if tag == 5: 0 else: 1, x)
      if s.found:
        if tag == 5:
          result = s.left
          result2 = cons(c, 0, s.item, s.right)
          aux = x
        else:
          result = snoc(c, 0, s.left, s.item)
          result2 = s.right
          aux = int64(treeMeasure(c, result).count)
      else:
        result = source
        result2 = emptyTree(c, 0)
        aux = if tag == 5: x else: -1
      two = true
    if c.failed: return -1
    let lm = treeMeasure(c, result)
    if lm.count > 64 or lm.sum > SUMMAX: return -1
    let leftID = nr
    roots[nr] = Root(tree: result, length: lm.count, sum: lm.sum)
    inc nr
    var rightLen = -1'i64
    var rightSum = -1'i64
    if two:
      if nr >= ROOTS: return -1
      let rm = treeMeasure(c, result2)
      if rm.count > 64 or rm.sum > SUMMAX: return -1
      rightRoot = int32(nr)
      rightLen = int64(rm.count)
      rightSum = rm.sum
      roots[nr] = Root(tree: result2, length: rm.count, sum: rm.sum)
      inc nr
    let o = 7*op
    records[o] = int64(leftID); records[o+1] = int64(lm.count); records[o+2] = lm.sum
    records[o+3] = int64(rightRoot); records[o+4] = rightLen; records[o+5] = rightSum; records[o+6] = aux
  let bytes = 56*q
  if output == nil or capacity < csize_t(bytes): return -2
  var staged: array[MAX_OUTPUT, uint8]
  for i in 0 ..< q*7: put64(cast[ptr UncheckedArray[uint8]](addr staged[0]), i*8, records[i])
  for i in 0 ..< bytes: output[i] = staged[i]
  int64(bytes)

proc measured_finger_tree_sequence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.exportc, dynlib.} =
  measured_finger_tree_sequence_impl(input, length, output, capacity)
