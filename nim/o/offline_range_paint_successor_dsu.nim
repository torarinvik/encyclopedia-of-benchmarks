const MaxN = 64
const MaxQ = 64
const MaxInputLength = 195

proc findSuccessor(parent: var array[65, int64], node: int): int =
  var root = node
  while int(parent[root]) != root: root = int(parent[root])
  var current = node
  while int(parent[current]) != current:
    let next = int(parent[current])
    parent[current] = int64(root)
    current = next
  root

proc offline_range_paint_successor_dsu*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "offline_range_paint_successor_dsu".} =
  if input.isNil or length < 2 or length > MaxInputLength: return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + 3 * q): return -1
  var left: array[64, int64]
  var right: array[64, int64]
  var color: array[64, int64]
  for j in 0 ..< q:
    left[j] = input[2 + 3 * j]
    right[j] = input[3 + 3 * j]
    color[j] = input[4 + 3 * j]
    if left[j] < 0 or left[j] > right[j] or right[j] >= nValue or color[j] < -1000 or color[j] > 1000: return -1
  var parent: array[65, int64]
  var finalColor: array[64, int64]
  for i in 0 .. n: parent[i] = int64(i)
  for reverseIndex in 0 ..< q:
    let operation = q - reverseIndex - 1
    var cell = findSuccessor(parent, int(left[operation]))
    while cell <= int(right[operation]):
      finalColor[cell] = color[operation]
      parent[cell] = int64(findSuccessor(parent, cell + 1))
      cell = findSuccessor(parent, cell)
  var checksum = 0'i64
  for i in 0 ..< n: checksum += int64(i + 1) * (finalColor[i] + 1001)
  checksum
