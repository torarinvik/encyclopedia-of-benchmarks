const MaxItems = 256
const MaxOperations = 512
const MaxInputValues = 2 + 3 * MaxOperations
const ValueLimit = 1_000_000'i64
const QueryOffset = 131_072_000_001'i64
const FinalOffset = 512_000_001'i64

proc lowbit(index: int): int = index and -index

proc prefixSum(tree: var array[MaxItems + 1, int64], count: int): int64 =
  var index = count
  var total = 0'i64
  while index > 0:
    total += tree[index]
    index -= lowbit(index)
  total

proc fenwick_tree_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fenwick_tree_benchmark".} =
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
    if opcode == 0:
      if first < 0 or first >= itemCountValue or second < -ValueLimit or second > ValueLimit: return -1
    elif opcode == 1:
      if first < 0 or second < first or second >= itemCountValue: return -1
    else:
      return -1

  var data: array[MaxItems, int64]
  var tree: array[MaxItems + 1, int64]
  var checksum = 0'i64
  for operation in 0 ..< operationCount:
    let position = 2 + 3 * operation
    let opcode = values[position]
    let first = values[position + 1].int
    let second = values[position + 2]
    if opcode == 0:
      data[first] += second
      var index = first + 1
      while index <= itemCount:
        tree[index] += second
        index += lowbit(index)
    else:
      let right = second.int
      let result = prefixSum(tree, right + 1) - prefixSum(tree, first)
      checksum += (operation + 1).int64 * (result + QueryOffset)
  for i in 0 ..< itemCount:
    checksum += (operationCount + i + 1).int64 * (data[i] + FinalOffset)
  checksum
