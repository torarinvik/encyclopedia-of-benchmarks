const MaxItems = 256
const MaxOperations = 512
const MaxInputValues = 2 + 3 * MaxOperations
const ObservedOffset = 1_000_003'i64

proc findRoot(parent: var array[MaxItems, int], item: int): int =
  var current = item
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  current

proc union_find_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "union_find_benchmark".} =
  if length < 2 or length > MaxInputValues.csize_t: return -1
  let itemCountValue = values[0]
  let operationCountValue = values[1]
  if itemCountValue < 1 or itemCountValue > MaxItems.int64: return -1
  if operationCountValue < 0 or operationCountValue > MaxOperations.int64: return -1
  let itemCount = itemCountValue.int
  let operationCount = operationCountValue.int
  if length.int != 2 + 3 * operationCount: return -1

  for operation in 0 ..< operationCount:
    let position = 2 + 3 * operation
    let opcode = values[position]
    let first = values[position + 1]
    let second = values[position + 2]
    if opcode == 0 or opcode == 1:
      if first < 0 or first >= itemCountValue or second < 0 or second >= itemCountValue: return -1
    elif opcode == 2:
      if first != 0 or second != 0: return -1
    else:
      return -1

  var parent: array[MaxItems, int]
  var setSize: array[MaxItems, int]
  for i in 0 ..< itemCount:
    parent[i] = i
    setSize[i] = 1
  var components = itemCount
  var connectedPairs = 0'i64
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let position = 2 + 3 * operation
    let opcode = values[position]
    let first = values[position + 1].int
    let second = values[position + 2].int
    var observed = 0'i64
    if opcode == 0:
      let firstRoot = findRoot(parent, first)
      let secondRoot = findRoot(parent, second)
      if firstRoot != secondRoot:
        connectedPairs += (setSize[firstRoot] * setSize[secondRoot]).int64
        if setSize[firstRoot] < setSize[secondRoot]:
          parent[firstRoot] = secondRoot
          setSize[secondRoot] += setSize[firstRoot]
        else:
          parent[secondRoot] = firstRoot
          setSize[firstRoot] += setSize[secondRoot]
        dec components
        observed = 1
    elif opcode == 1:
      observed = int64(findRoot(parent, first) == findRoot(parent, second))
    else:
      observed = components.int64
    checksum += (operation + 1).int64 * (observed + ObservedOffset)
  checksum + connectedPairs
