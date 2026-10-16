const MaxItems = 256
const MaxOperations = 512
const MaxInputValues = 2 + 3 * MaxOperations
const ValueLimit = 1_000_000'i64
const QueryOffset = 131_072_000_001'i64
const FinalOffset = 512_000_001'i64

proc lowbit(index: int): int = index and -index
proc prefixSum(tree: array[MaxItems + 2, int32], initial: int): int32 =
  var count = initial
  var sum = 0'i32
  while count > 0:
    sum += tree[count]
    count -= lowbit(count)
  sum

proc binary_indexed_tree*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "binary_indexed_tree".} =
  if values.isNil or length < csize_t(2) or length > csize_t(MaxInputValues): return -1
  let nValue = values[0]
  let opValue = values[1]
  if nValue < 2 or nValue > int64(MaxItems) or (nValue and (nValue - 1)) != 0 or opValue < 0 or opValue > int64(MaxOperations): return -1
  let n = int(nValue)
  let operations = int(opValue)
  if int(length) != 2 + 3 * operations: return -1
  for op in 0 ..< operations:
    let at = 2 + 3 * op
    let code = values[at]
    let first = values[at + 1]
    let second = values[at + 2]
    if code == 0:
      if first < 0 or first >= nValue or second < -ValueLimit or second > ValueLimit: return -1
    elif code == 1:
      if first < 0 or second < first or second >= nValue: return -1
    else:
      return -1
  var data: array[MaxItems, int32]
  var tree: array[MaxItems + 2, int32]
  var checksum = 0'i64
  for op in 0 ..< operations:
    let at = 2 + 3 * op
    let code = values[at]
    let first = int(values[at + 1])
    let second = values[at + 2]
    if code == 0:
      let delta = int32(second)
      data[first] += delta
      var start = first + 1
      while start <= n + 1:
        tree[start] += delta
        start += lowbit(start)
    else:
      let result = prefixSum(tree, int(second) + 1) - prefixSum(tree, int(first))
      checksum += int64(op + 1) * (int64(result) + QueryOffset)
  for i in 0 ..< n:
    checksum += int64(operations + i + 1) * (int64(data[i]) + FinalOffset)
  checksum
