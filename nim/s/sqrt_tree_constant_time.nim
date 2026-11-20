const MaxN = 64
const MaxQ = 64
const MaxLevels = 4
const MaxInput = 195
const ValueLimit = 1_000_000_000'i64
const Infinity = high(int64)

type SqrtTreeConstantState = object
  values: array[MaxN, int64]
  prefix: array[MaxLevels * MaxN, int64]
  suffix: array[MaxLevels * MaxN, int64]
  between: array[MaxLevels * MaxN, int64]
  floorLog: array[MaxN + 1, int]
  padded, layerCount: int
  segmentBits, blockBits: array[MaxLevels, int]
  layerForDiff: array[MaxLevels + 3, int]

proc build(state: var SqrtTreeConstantState, input: ptr UncheckedArray[int64], n: int) =
  var padded = 1
  while padded < n: padded *= 2
  state.padded = padded
  for i in 0 ..< n: state.values[i] = input[2 + i]
  for i in n ..< padded: state.values[i] = Infinity
  state.floorLog[0] = 0
  state.floorLog[1] = 0
  var i = 2
  while i <= padded:
    state.floorLog[i] = state.floorLog[i div 2] + 1
    inc i
  for i in 0 ..< MaxLevels + 3: state.layerForDiff[i] = -1

  var bits = state.floorLog[padded]
  while bits > 1:
    let level = state.layerCount
    inc state.layerCount
    let blockBits = (bits + 1) div 2
    state.segmentBits[level] = bits
    state.blockBits[level] = blockBits
    for bit in blockBits ..< bits: state.layerForDiff[bit] = level
    bits = blockBits

  for level in 0 ..< state.layerCount:
    let segmentBits = state.segmentBits[level]
    let blockBits = state.blockBits[level]
    let segmentSize = 1 shl segmentBits
    let blockSize = 1 shl blockBits
    let blockCount = segmentSize div blockSize
    let pairCount = blockCount * blockCount
    var base = 0
    while base < padded:
      let segmentIndex = base div segmentSize
      for block in 0 ..< blockCount:
        let start = base + block * blockSize
        let finish = start + blockSize
        state.prefix[level * MaxN + start] = state.values[start]
        for pos in start + 1 ..< finish:
          state.prefix[level * MaxN + pos] = min(state.prefix[level * MaxN + pos - 1], state.values[pos])
        state.suffix[level * MaxN + finish - 1] = state.values[finish - 1]
        var pos = finish - 1
        while pos > start:
          dec pos
          state.suffix[level * MaxN + pos] = min(state.values[pos], state.suffix[level * MaxN + pos + 1])
      for leftBlock in 0 ..< blockCount:
        var aggregate = Infinity
        for rightBlock in leftBlock ..< blockCount:
          let start = base + rightBlock * blockSize
          aggregate = min(aggregate, state.suffix[level * MaxN + start])
          let slot = segmentIndex * pairCount + leftBlock * blockCount + rightBlock
          state.between[level * MaxN + slot] = aggregate
      base += segmentSize

proc query(state: SqrtTreeConstantState, left, right: int): int64 =
  if left == right: return state.values[left]
  let bit = state.floorLog[left xor right]
  if bit == 0: return min(state.values[left], state.values[right])
  let level = state.layerForDiff[bit]
  let segmentSize = 1 shl state.segmentBits[level]
  let blockSize = 1 shl state.blockBits[level]
  let base = (left div segmentSize) * segmentSize
  let segmentIndex = base div segmentSize
  let blockCount = segmentSize div blockSize
  let leftBlock = (left - base) div blockSize
  let rightBlock = (right - base) div blockSize
  result = min(state.suffix[level * MaxN + left], state.prefix[level * MaxN + right])
  if leftBlock + 1 < rightBlock:
    let pairCount = blockCount * blockCount
    let slot = segmentIndex * pairCount + (leftBlock + 1) * blockCount + rightBlock - 1
    result = min(result, state.between[level * MaxN + slot])

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc sqrt_tree_constant_time*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "sqrt_tree_constant_time".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 2 + n + 2 * q: return -1
  for i in 0 ..< n:
    if input[2 + i] < -ValueLimit or input[2 + i] > ValueLimit: return -1
  let queryOffset = 2 + n
  for query in 0 ..< q:
    let left = input[queryOffset + 2 * query]
    let right = input[queryOffset + 2 * query + 1]
    if left < 0 or right < left or right >= nValue: return -1
  let required = 8 * q
  if outputCapacity < csize_t(required) or (required > 0 and output.isNil): return -2
  var state: SqrtTreeConstantState
  build(state, input, n)
  for query in 0 ..< q:
    let left = int(input[queryOffset + 2 * query])
    let right = int(input[queryOffset + 2 * query + 1])
    storeI64Le(output, 8 * query, query(state, left, right))
  int64(required)
