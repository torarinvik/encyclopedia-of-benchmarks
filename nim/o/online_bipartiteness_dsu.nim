const MaxN = 32
const MaxQ = 64
const MaxInputLength = 195

proc findParity(parent: var array[32, int64], parity: var array[32, int64], node: int): tuple[root: int, offset: int64] =
  var root = node
  var total = 0'i64
  while int(parent[root]) != root:
    total = total xor parity[root]
    root = int(parent[root])
  var current = node
  var accumulated = 0'i64
  while int(parent[current]) != current:
    let next = int(parent[current])
    let edge = parity[current]
    parent[current] = int64(root)
    parity[current] = total xor accumulated
    accumulated = accumulated xor edge
    current = next
  (root, total)

proc online_bipartiteness_dsu*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "online_bipartiteness_dsu".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + 3 * q): return -1
  for j in 0 ..< q:
    let opcode = input[2 + 3 * j]
    let a = input[3 + 3 * j]
    let b = input[4 + 3 * j]
    if opcode == 0:
      if a < 0 or a >= nValue or b < 0 or b >= nValue: return -1
    elif opcode == 1:
      if a < 0 or a >= nValue or b != 0: return -1
    else:
      return -1
  var parent: array[32, int64]
  var size: array[32, int64]
  var parity: array[32, int64]
  var bad: array[32, bool]
  for i in 0 ..< n:
    parent[i] = int64(i)
    size[i] = 1
  var checksum = 0'i64
  var queryOrdinal = 0'i64
  for operation in 0 ..< q:
    let opcode = input[2 + 3 * operation]
    let a = int(input[3 + 3 * operation])
    if opcode == 1:
      let found = findParity(parent, parity, a)
      let answer = if bad[found.root]: 0'i64 else: 1'i64
      checksum += (queryOrdinal + 1) * (answer + 1)
      inc queryOrdinal
      continue
    let b = int(input[4 + 3 * operation])
    var foundA = findParity(parent, parity, a)
    var foundB = findParity(parent, parity, b)
    if foundA.root == foundB.root:
      if foundA.offset == foundB.offset: bad[foundA.root] = true
      continue
    if size[foundA.root] < size[foundB.root]: swap(foundA, foundB)
    parent[foundB.root] = int64(foundA.root)
    parity[foundB.root] = foundA.offset xor foundB.offset xor 1
    size[foundA.root] += size[foundB.root]
    bad[foundA.root] = bad[foundA.root] or bad[foundB.root]
  checksum
