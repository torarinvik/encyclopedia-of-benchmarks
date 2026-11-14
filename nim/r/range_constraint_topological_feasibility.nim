## Independent compressed event-graph draft; uncompiled and unrun.
type
  EventGraph = object
    edges: seq[seq[int]]
    degree: seq[int]
    first: seq[bool]
  Trees = object
    down, up, any: seq[int]

proc newNode(g: var EventGraph, first: bool): int =
  result = g.edges.len
  g.edges.add(@[])
  g.degree.add(0)
  g.first.add(first)

proc addEdge(g: var EventGraph, source, target: int) =
  g.edges[source].add(target)
  inc g.degree[target]

proc build(t: var Trees, g: var EventGraph, node, left, right: int) =
  t.down[node] = g.newNode(false)
  t.up[node] = g.newNode(false)
  t.any[node] = g.newNode(true)
  if right-left == 1:
    g.addEdge(t.down[node], left)
    g.addEdge(left, t.up[node])
    g.addEdge(left, t.any[node])
    return
  let middle = left + (right-left) div 2
  t.build(g, 2*node, left, middle)
  t.build(g, 2*node+1, middle, right)
  for child in [2*node, 2*node+1]:
    g.addEdge(t.down[node], t.down[child])
    g.addEdge(t.up[child], t.up[node])
    g.addEdge(t.any[child], t.any[node])

proc connect(t: Trees, g: var EventGraph, node, left, right, ql, qr, kind, target: int) =
  if ql <= left and right <= qr:
    case kind
    of 1: g.addEdge(target, t.down[node])
    of 2: g.addEdge(t.up[node], target)
    else: g.addEdge(t.any[node], target)
    return
  let middle = left + (right-left) div 2
  if ql < middle: t.connect(g, 2*node, left, middle, ql, qr, kind, target)
  if qr > middle: t.connect(g, 2*node+1, middle, right, ql, qr, kind, target)

proc range_constraint_topological_feasibility*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "range_constraint_topological_feasibility".} =
  if input.isNil or length < 2 or input[0] < 1 or input[0] > 4096 or input[1] < 0 or input[1] > 8192:
    return -1
  let n = int(input[0]); let m = int(input[1])
  if length != csize_t(2+4*m): return -1
  for i in 0 ..< m:
    let kind=input[2+4*i]; let left=input[3+4*i]
    let right=input[4+4*i]; let target=input[5+4*i]
    if kind < 1 or kind > 3 or left < 0 or left >= right or right > int64(n) or
        target < 0 or target >= int64(n) or (left <= target and target < right): return -1
  var graph: EventGraph
  for i in 0 ..< n: discard graph.newNode(false)
  var trees = Trees(down: newSeq[int](4*n), up: newSeq[int](4*n), any: newSeq[int](4*n))
  trees.build(graph, 1, 0, n)
  for i in 0 ..< m:
    let kind=int(input[2+4*i]); let left=int(input[3+4*i])
    let right=int(input[4+4*i]); let target=int(input[5+4*i])
    if kind == 3:
      let gate=graph.newNode(true)
      trees.connect(graph, 1, 0, n, left, right, kind, gate)
      graph.addEdge(gate, target)
    else:
      trees.connect(graph, 1, 0, n, left, right, kind, target)
  var queue: seq[int] = @[]
  for i in 0 ..< graph.degree.len:
    if graph.first[i]: graph.degree[i] = 1
    if graph.degree[i] == 0: queue.add(i)
  var head=0; var emitted=0
  while head < queue.len:
    let node=queue[head]
    inc head
    if node < n: inc emitted
    for target in graph.edges[node]:
      if graph.degree[target] > 0:
        dec graph.degree[target]
        if graph.degree[target] == 0: queue.add(target)
  if emitted == n: 1 else: 0
