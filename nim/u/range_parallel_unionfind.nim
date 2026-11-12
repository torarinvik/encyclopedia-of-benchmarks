const MaxN = 64
const MaxQ = 64
const MaxLevels = 6
const MaxInputValues = 2 + MaxN + 3 * MaxQ
const Modulus = 998_244_353'i64
type Layers = array[MaxLevels, array[MaxN, int]]

proc normalize(value: int64): int64 =
  let reduced = value mod Modulus
  if reduced < 0: reduced + Modulus else: reduced

proc findRoot(parent: var Layers, level, item: int): int =
  if parent[level][item] != item:
    parent[level][item] = findRoot(parent, level, parent[level][item])
  parent[level][item]

proc mergeInner(level, left, right: int, parent, setSize: var Layers,
    weight: var array[MaxN, int64], pairSum: var int64) =
  var rootLeft = findRoot(parent, level, left)
  var rootRight = findRoot(parent, level, right)
  if rootLeft == rootRight: return
  if setSize[level][rootLeft] < setSize[level][rootRight]:
    swap(rootLeft, rootRight)
  parent[level][rootRight] = rootLeft
  setSize[level][rootLeft] += setSize[level][rootRight]
  if level == 0:
    pairSum = normalize(pairSum + weight[rootLeft] * weight[rootRight])
    weight[rootLeft] = normalize(weight[rootLeft] + weight[rootRight])
    return
  let half = 1 shl (level - 1)
  mergeInner(level - 1, left, right, parent, setSize, weight, pairSum)
  mergeInner(level - 1, left + half, right + half, parent, setSize, weight, pairSum)

proc floorLog2(value: int): int =
  var remaining = value
  while remaining > 1:
    remaining = remaining shr 1
    inc result

proc mergeRanges(length, left, right: int, parent, setSize: var Layers,
    weight: var array[MaxN, int64], pairSum: var int64) =
  if length == 0: return
  let level = floorLog2(length - 1)
  let block = 1 shl level
  mergeInner(level, left, right, parent, setSize, weight, pairSum)
  mergeInner(level, left + length - block, right + length - block,
             parent, setSize, weight, pairSum)

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc range_parallel_unionfind*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "range_parallel_unionfind".} =
  if input.isNil or length < 6 or length > csize_t(MaxInputValues): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 1 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if length != csize_t(2 + n + 3 * q): return -1
  for item in 0 ..< n:
    if input[2 + item] < 0 or input[2 + item] >= Modulus: return -1
  let operationsAt = 2 + n
  for operation in 0 ..< q:
    let position = operationsAt + 3 * operation
    let span = input[position]
    let left = input[position + 1]
    let right = input[position + 2]
    if span < 0 or span > nValue or left < 0 or right < 0 or
       left > nValue - span or right > nValue - span: return -1
  let required = 8 * q
  if output.isNil or capacity < csize_t(required): return -2

  var parent: Layers
  var setSize: Layers
  var weight: array[MaxN, int64]
  for level in 0 ..< MaxLevels:
    let block = 1 shl level
    if block > n: break
    for start in 0 .. n - block:
      parent[level][start] = start
      setSize[level][start] = 1
  for item in 0 ..< n: weight[item] = input[2 + item]
  var pairSum = 0'i64
  for operation in 0 ..< q:
    let position = operationsAt + 3 * operation
    mergeRanges(int(input[position]), int(input[position + 1]), int(input[position + 2]),
                parent, setSize, weight, pairSum)
    storeI64Le(output, 8 * operation, pairSum)
  int64(required)
