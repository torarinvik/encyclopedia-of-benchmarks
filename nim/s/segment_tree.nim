const MaxItems = 256
const MaxOperations = 512
const MaxInputValues = MaxItems + 3 + 3 * MaxOperations
const ValueLimit = 1_000_000'i64
const QueryOffset = 256_000_001'i64
const FinalOffset = 1_000_001'i64

proc identity(mode: int64): int64 =
  if mode == 1: ValueLimit + 1
  elif mode == 2: -(ValueLimit + 1)
  else: 0

proc combine(mode, left, right: int64): int64 =
  if mode == 1: min(left, right)
  elif mode == 2: max(left, right)
  else: left + right

proc segment_tree_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "segment_tree_benchmark".} =
  if length < 3 or length > MaxInputValues.csize_t: return -1
  let mode = values[0]
  let itemCountValue = values[1]
  if mode < 0 or mode > 2 or itemCountValue < 1 or itemCountValue > MaxItems.int64: return -1
  let itemCount = itemCountValue.int
  if length.int < itemCount + 3: return -1
  let operationCountValue = values[itemCount + 2]
  if operationCountValue < 0 or operationCountValue > MaxOperations.int64: return -1
  let operationCount = operationCountValue.int
  if length.int != itemCount + 3 + 3 * operationCount: return -1

  var data: array[MaxItems, int64]
  for i in 0 ..< itemCount:
    let value = values[i + 2]
    if value < -ValueLimit or value > ValueLimit: return -1
    data[i] = value
  for operation in 0 ..< operationCount:
    let position = itemCount + 3 + 3 * operation
    let opcode = values[position]
    let first = values[position + 1]
    let second = values[position + 2]
    if opcode == 0:
      if first < 0 or first >= itemCountValue or second < -ValueLimit or second > ValueLimit: return -1
    elif opcode == 1:
      if first < 0 or second < first or second >= itemCountValue: return -1
    else:
      return -1

  var base = 1
  while base < itemCount: base *= 2
  let empty = identity(mode)
  var tree: array[2 * MaxItems, int64]
  for i in 0 ..< 2 * base: tree[i] = empty
  for i in 0 ..< itemCount: tree[base + i] = data[i]
  var node = base
  while node > 1:
    dec node
    tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1])

  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let position = itemCount + 3 + 3 * operation
    let opcode = values[position]
    let first = values[position + 1].int
    if opcode == 0:
      let value = values[position + 2]
      data[first] = value
      node = base + first
      tree[node] = value
      while node > 1:
        node = node div 2
        tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1])
    else:
      var left = base + first
      var right = base + values[position + 2].int + 1
      var result = empty
      while left < right:
        if left mod 2 == 1:
          result = combine(mode, result, tree[left])
          inc left
        if right mod 2 == 1:
          dec right
          result = combine(mode, result, tree[right])
        left = left div 2
        right = right div 2
      checksum += (operation + 1).int64 * (result + QueryOffset)
  for i in 0 ..< itemCount:
    checksum += (operationCount + i + 1).int64 * (data[i] + FinalOffset)
  checksum
