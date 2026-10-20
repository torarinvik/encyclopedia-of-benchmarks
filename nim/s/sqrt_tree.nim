# Adapted from cp-algorithms Sqrt Tree; CC BY-SA 4.0, see package LICENSE.txt.
const MaxItems = 256
const MaxQueries = 256
const MaxLevels = 16
const MaxNodes = 512
const MaxBetween = 512
const MaxInputValues = 770
const ValueLimit = 1_000_000_000'i64

type SqrtTreeState = object
  values: array[MaxItems, int64]
  prefix: array[MaxLevels * MaxItems, int64]
  suffix: array[MaxLevels * MaxItems, int64]
  between: array[MaxLevels * MaxBetween, int64]
  usedValues: array[MaxLevels, int]
  usedBetween: array[MaxLevels, int]
  nodeLeft: array[MaxNodes, int]
  nodeRight: array[MaxNodes, int]
  nodeDepth: array[MaxNodes, int]
  valueOffset: array[MaxNodes, int]
  betweenOffset: array[MaxNodes, int]
  blockSize: array[MaxNodes, int]
  blockCount: array[MaxNodes, int]
  childStart: array[MaxNodes, int]
  children: array[MaxNodes, int]
  nodeCount: int
  childCount: int

proc createNode(state: var SqrtTreeState, left, right, depth: int): int =
  result = state.nodeCount
  inc state.nodeCount
  state.nodeLeft[result] = left
  state.nodeRight[result] = right
  state.nodeDepth[result] = depth

proc buildNode(state: var SqrtTreeState, node: int) =
  let left = state.nodeLeft[node]
  let right = state.nodeRight[node]
  let nodeLength = right - left
  let depth = state.nodeDepth[node]
  if nodeLength <= 2: return
  var blockSize = 1
  while blockSize * blockSize < nodeLength: inc blockSize
  let blockCount = (nodeLength + blockSize - 1) div blockSize
  let valueOffset = state.usedValues[depth]
  let betweenOffset = state.usedBetween[depth]
  state.valueOffset[node] = valueOffset
  state.betweenOffset[node] = betweenOffset
  state.blockSize[node] = blockSize
  state.blockCount[node] = blockCount
  state.usedValues[depth] += nodeLength
  state.usedBetween[depth] += blockCount * blockCount

  var blockMin: array[MaxItems, int64]
  for block in 0 ..< blockCount:
    let start = left + block * blockSize
    let finish = min(start + blockSize, right)
    let first = valueOffset + start - left
    state.prefix[depth * MaxItems + first] = state.values[start]
    for index in start + 1 ..< finish:
      let slot = valueOffset + index - left
      state.prefix[depth * MaxItems + slot] = min(state.prefix[depth * MaxItems + slot - 1], state.values[index])
    let last = valueOffset + finish - 1 - left
    state.suffix[depth * MaxItems + last] = state.values[finish - 1]
    var index = finish - 1
    while index > start:
      let slot = valueOffset + index - 1 - left
      state.suffix[depth * MaxItems + slot] = min(state.values[index - 1], state.suffix[depth * MaxItems + slot + 1])
      dec index
    blockMin[block] = state.prefix[depth * MaxItems + last]
  for first in 0 ..< blockCount:
    var aggregate = blockMin[first]
    for last in first ..< blockCount:
      if last != first: aggregate = min(aggregate, blockMin[last])
      state.between[depth * MaxBetween + betweenOffset + first * blockCount + last] = aggregate

  let childStart = state.childCount
  state.childStart[node] = childStart
  for block in 0 ..< blockCount:
    let start = left + block * blockSize
    let finish = min(start + blockSize, right)
    let child = createNode(state, start, finish, depth + 1)
    state.children[state.childCount] = child
    inc state.childCount
  for block in 0 ..< blockCount: buildNode(state, state.children[childStart + block])

proc queryNode(state: var SqrtTreeState, node, left, right: int): int64 =
  let nodeLeft = state.nodeLeft[node]
  let nodeRight = state.nodeRight[node]
  if nodeRight - nodeLeft <= 2:
    result = state.values[left]
    var index = left + 1
    while index <= right:
      result = min(result, state.values[index])
      inc index
    return
  let blockSize = state.blockSize[node]
  let leftBlock = (left - nodeLeft) div blockSize
  let rightBlock = (right - nodeLeft) div blockSize
  if leftBlock == rightBlock:
    return queryNode(state, state.children[state.childStart[node] + leftBlock], left, right)
  let depth = state.nodeDepth[node]
  let offset = state.valueOffset[node]
  result = state.suffix[depth * MaxItems + offset + left - nodeLeft]
  if leftBlock + 1 < rightBlock:
    let count = state.blockCount[node]
    let middle = state.betweenOffset[node] + (leftBlock + 1) * count + rightBlock - 1
    result = min(result, state.between[depth * MaxBetween + middle])
  result = min(result, state.prefix[depth * MaxItems + offset + right - nodeLeft])

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc sqrt_tree*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sqrt_tree".} =
  if input == nil or length < 2 or length > csize_t(MaxInputValues): return -1
  let itemCountValue = input[0]
  let queryCountValue = input[1]
  if itemCountValue < 1 or itemCountValue > MaxItems or queryCountValue < 0 or queryCountValue > MaxQueries:
    return -1
  let itemCount = int(itemCountValue)
  let queryCount = int(queryCountValue)
  if int(length) != 2 + itemCount + 2 * queryCount: return -1
  for index in 0 ..< itemCount:
    if input[2 + index] < -ValueLimit or input[2 + index] > ValueLimit: return -1
  let queryOffset = 2 + itemCount
  for query in 0 ..< queryCount:
    let left = input[queryOffset + 2 * query]
    let right = input[queryOffset + 2 * query + 1]
    if left < 0 or right < left or right >= itemCountValue: return -1
  let required = 8 * queryCount
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2

  var state: SqrtTreeState
  for index in 0 ..< itemCount: state.values[index] = input[index + 2]
  let root = createNode(state, 0, itemCount, 0)
  buildNode(state, root)
  for query in 0 ..< queryCount:
    let left = int(input[queryOffset + 2 * query])
    let right = int(input[queryOffset + 2 * query + 1])
    storeI64Le(output, 8 * query, queryNode(state, root, left, right))
  int64(required)
