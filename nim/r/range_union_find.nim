const
  MaxN = 32
  MaxQ = 32
  MaxParseableLength = 99

proc findRoot(parent: var array[MaxN, int64], vertexInput: int): int =
  var vertex = vertexInput
  while parent[vertex] >= 0:
    let ancestor = int(parent[vertex])
    if parent[ancestor] >= 0: parent[vertex] = parent[ancestor]
    vertex = ancestor
  vertex

proc uniteRoots(parent: var array[MaxN, int64], left, right: var array[MaxN, int64],
                rootAInput, rootBInput: int): int =
  var rootA = rootAInput
  var rootB = rootBInput
  if parent[rootA] > parent[rootB]: swap(rootA, rootB)
  parent[rootA] += parent[rootB]
  parent[rootB] = int64(rootA)
  left[rootA] = min(left[rootA], left[rootB])
  right[rootA] = max(right[rootA], right[rootB])
  rootA

proc range_union_find*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "range_union_find".} =
  if values == nil or length < 2 or length > csize_t(MaxParseableLength): return -1
  let nValue = values[0]
  let qValue = values[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ or
      int(length) != 2 + 3 * int(qValue): return -1
  let n = int(nValue)
  let q = int(qValue)
  for operation in 0 ..< q:
    let offset = 2 + 3 * operation
    let opcode = values[offset]
    let first = values[offset + 1]
    let second = values[offset + 2]
    if opcode == 0:
      if first < 0 or first > second or second > nValue: return -1
    elif opcode == 1:
      if first < 0 or first >= nValue or second < 0 or second >= nValue: return -1
    elif opcode == 2:
      if first < 0 or first >= nValue or second != 0: return -1
    else: return -1

  var parent: array[MaxN, int64]
  var left, right: array[MaxN, int64]
  for vertex in 0 ..< n:
    parent[vertex] = -1
    left[vertex] = int64(vertex)
    right[vertex] = int64(vertex + 1)
  var components = n
  var total = 0'i64
  for operation in 0 ..< q:
    let offset = 2 + 3 * operation
    let opcode = values[offset]
    let first = int(values[offset + 1])
    let second = int(values[offset + 2])
    var observed: int64
    if opcode == 0:
      if first < second:
        var root = findRoot(parent, first)
        var next = int(right[root])
        while next < second:
          let nextRoot = findRoot(parent, next)
          if root == nextRoot: break
          root = uniteRoots(parent, left, right, root, nextRoot)
          dec components
          next = int(right[root])
      observed = int64(components)
    elif opcode == 1:
      observed = int64(ord(findRoot(parent, first) == findRoot(parent, second)))
    else:
      observed = -parent[findRoot(parent, first)]
    total += int64(operation + 1) * observed
  total
