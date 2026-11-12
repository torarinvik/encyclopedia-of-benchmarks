const MaxN = 64
const MaxQ = 64
const MaxInputValues = 2 + 4 * MaxQ

proc findRoot(parent: var array[MaxN, int], item: int): int =
  var current = item
  while parent[current] != current:
    current = parent[current]
  current

proc visitVersion(node: int, kind, u, v: var array[MaxQ, int64],
    firstChild: var array[MaxQ + 1, int], nextSibling: var array[MaxQ, int],
    parent, setSize: var array[MaxN, int], answer: var array[MaxQ + 1, int64],
    historyChild, historyRoot, historySize: var array[MaxQ, int64],
    historyCount: var int) =
  let savedHistory = historyCount
  if node != 0:
    let operation = node - 1
    if kind[operation] == 0:
      var rootU = findRoot(parent, int(u[operation]))
      var rootV = findRoot(parent, int(v[operation]))
      if rootU == rootV:
        historyChild[historyCount] = -1
        historyRoot[historyCount] = -1
        historySize[historyCount] = 0
      else:
        if setSize[rootU] > setSize[rootV]: swap(rootU, rootV)
        historyChild[historyCount] = int64(rootU)
        historyRoot[historyCount] = int64(rootV)
        historySize[historyCount] = int64(setSize[rootV])
        parent[rootU] = rootV
        setSize[rootV] += setSize[rootU]
      inc historyCount
    else:
      if findRoot(parent, int(u[operation])) == findRoot(parent, int(v[operation])):
        answer[node] = 1
      else:
        answer[node] = 0
  var child = firstChild[node]
  while child >= 0:
    visitVersion(child, kind, u, v, firstChild, nextSibling, parent, setSize,
                 answer, historyChild, historyRoot, historySize, historyCount)
    child = nextSibling[child - 1]
  while historyCount > savedHistory:
    dec historyCount
    let changedChild = historyChild[historyCount]
    if changedChild >= 0:
      let root = int(historyRoot[historyCount])
      parent[int(changedChild)] = int(changedChild)
      setSize[root] = int(historySize[historyCount])

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc persistent_unionfind*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "persistent_unionfind".} =
  if input.isNil or length < 6 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 1 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + 4 * q): return -1

  var kind, u, v: array[MaxQ, int64]
  var firstChild: array[MaxQ + 1, int]
  var nextSibling: array[MaxQ, int]
  var answer: array[MaxQ + 1, int64]
  for node in 0 .. q: firstChild[node] = -1
  var queryCount = 0
  for operation in 0 ..< q:
    let offset = 2 + 4 * operation
    kind[operation] = input[offset]
    let version = input[offset + 1]
    u[operation] = input[offset + 2]
    v[operation] = input[offset + 3]
    if (kind[operation] != 0 and kind[operation] != 1) or version < -1 or
       version >= int64(operation) or u[operation] < 0 or u[operation] >= nValue or
       v[operation] < 0 or v[operation] >= nValue: return -1
    if version >= 0 and kind[int(version)] != 0: return -1
    if kind[operation] == 1: inc queryCount
    let parentNode = int(version + 1)
    nextSibling[operation] = firstChild[parentNode]
    firstChild[parentNode] = operation + 1

  let required = 8 * queryCount
  if output.isNil or capacity < csize_t(required): return -2
  var parent, setSize: array[MaxN, int]
  for item in 0 ..< n:
    parent[item] = item
    setSize[item] = 1
  var historyChild, historyRoot, historySize: array[MaxQ, int64]
  var historyCount = 0
  visitVersion(0, kind, u, v, firstChild, nextSibling, parent, setSize, answer,
               historyChild, historyRoot, historySize, historyCount)
  var written = 0
  for operation in 0 ..< q:
    if kind[operation] == 1:
      storeI64Le(output, written, answer[operation + 1])
      written += 8
  int64(written)
