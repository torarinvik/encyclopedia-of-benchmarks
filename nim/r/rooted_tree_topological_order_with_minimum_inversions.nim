const
  MaxN = 12
  MaxInputValues = 3 * MaxN + 1
  MaxOutputWords = MaxN + 1
  MaxWeight = 1_000_000'i64

proc findRoot(parent: var array[MaxN, int], vertex: int): int =
  var root = vertex
  while parent[root] != root: root = parent[root]
  var current = vertex
  while parent[current] != current:
    let next = parent[current]
    parent[current] = root
    current = next
  root

proc compareRatio(leftC, leftD, rightC, rightD: int64): int =
  let leftZero = leftC == 0 and leftD == 0
  let rightZero = rightC == 0 and rightD == 0
  if leftZero != rightZero: return (if leftZero: -1 else: 1)
  let lhs = leftC * rightD
  let rhs = leftD * rightC
  if lhs > rhs: 1 elif lhs < rhs: -1 else: 0

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc rooted_tree_topological_order_with_minimum_inversions*(
    input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "rooted_tree_topological_order_with_minimum_inversions".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN or length != csize_t(3 * nValue): return -1
  let n = int(nValue)

  var treeParent: array[MaxN, int]
  for vertex in 1 ..< n:
    let p = input[vertex]
    if p < 0 or p >= int64(vertex): return -1
    treeParent[vertex] = int(p)

  var originalC, originalD, aggregateC, aggregateD: array[MaxN, int64]
  var sumC = 0'i64
  var sumD = 0'i64
  for vertex in 0 ..< n:
    let c = input[n + vertex]
    let d = input[2 * n + vertex]
    if c < 0 or c > MaxWeight or d < 0 or d > MaxWeight: return -1
    sumC += c
    sumD += d
    if sumC > MaxWeight or sumD > MaxWeight: return -1
    originalC[vertex] = c
    originalD[vertex] = d
    aggregateC[vertex] = c
    aggregateD[vertex] = d

  var dsuParent, componentLabel, link: array[MaxN, int]
  var active: array[MaxN, bool]
  for vertex in 0 ..< n:
    dsuParent[vertex] = vertex
    componentLabel[vertex] = vertex
    active[vertex] = vertex != 0
    link[vertex] = vertex

  for _ in 0 ..< n - 1:
    var selected = -1
    for candidate in 1 ..< n:
      if not active[candidate]: continue
      if selected < 0:
        selected = candidate
        continue
      let comparison = compareRatio(aggregateC[candidate], aggregateD[candidate],
                                    aggregateC[selected], aggregateD[selected])
      if comparison > 0 or (comparison == 0 and candidate > selected):
        selected = candidate
    if selected < 0: return -1
    let parentComponent = findRoot(dsuParent, treeParent[selected])
    let target = componentLabel[parentComponent]
    let childComponent = findRoot(dsuParent, selected)
    if childComponent == parentComponent: return -1
    aggregateC[target] += aggregateC[selected]
    aggregateD[target] += aggregateD[selected]
    dsuParent[childComponent] = parentComponent
    componentLabel[parentComponent] = target
    active[selected] = false
    if target != 0: active[target] = true
    swap(link[selected], link[target])

  var traversal: array[MaxN, int]
  var count = 0
  var vertex = link[0]
  while count < n:
    traversal[count] = vertex
    inc count
    if vertex == 0: break
    vertex = link[vertex]
  if count != n or traversal[count - 1] != 0: return -1

  var words: array[MaxOutputWords, int64]
  var prefixD = 0'i64
  var objective = 0'i64
  for index in 0 ..< n:
    let orderedVertex = traversal[n - 1 - index]
    words[index + 1] = int64(orderedVertex)
    objective += prefixD * originalC[orderedVertex]
    prefixD += originalD[orderedVertex]
  words[0] = objective
  let outputBytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  for word in 0 ..< n + 1:
    storeI64Le(output, 8 * word, words[word])
  int64(outputBytes)
