const MaxLength = 64
const MaxOperations = 64
const MaxInput = 387
const BlockWidth = 8
const MaxBlocks = 8
const ChecksumOffset = 8_000_000'i64

type State = object
  data: array[MaxLength, int64]
  hullX: array[MaxLength, int64]
  hullY: array[MaxLength, int64]
  hullCount: array[MaxBlocks, int]
  lazySlope: array[MaxBlocks, int64]
  lazyIntercept: array[MaxBlocks, int64]
  n: int

proc blockEnd(state: State, block: int): int = min((block + 1) * BlockWidth, state.n)

proc rebuild(state: var State, block: int) =
  let base = block * BlockWidth
  var size = 0
  for x in base ..< state.blockEnd(block):
    while size >= 2:
      let p = base + size - 2
      let q = base + size - 1
      let cross = (state.hullX[q] - state.hullX[p]) * (state.data[x] - state.hullY[p]) -
        (state.hullY[q] - state.hullY[p]) * (int64(x) - state.hullX[p])
      if cross > 0: break
      dec size
    state.hullX[base + size] = int64(x)
    state.hullY[base + size] = state.data[x]
    inc size
  state.hullCount[block] = size

proc push(state: var State, block: int) =
  let start = block * BlockWidth
  for i in start ..< state.blockEnd(block):
    state.data[i] += state.lazySlope[block] * int64(i) + state.lazyIntercept[block]
  state.lazySlope[block] = 0
  state.lazyIntercept[block] = 0

proc blockMin(state: State, block: int): int64 =
  let base = block * BlockWidth
  var low = 0
  var high = state.hullCount[block] - 1
  while low < high:
    let middle = low + (high - low) div 2
    let left = state.hullY[base + middle] + state.lazySlope[block] * state.hullX[base + middle]
    let right = state.hullY[base + middle + 1] + state.lazySlope[block] * state.hullX[base + middle + 1]
    if left <= right: high = middle else: low = middle + 1
  state.hullY[base + low] + state.lazySlope[block] * state.hullX[base + low] + state.lazyIntercept[block]

proc update(state: var State, left, right: int, slope, intercept: int64) =
  var position = left
  while position < right:
    let block = position div BlockWidth
    let start = block * BlockWidth
    let finish = state.blockEnd(block)
    if position == start and finish <= right:
      state.lazySlope[block] += slope
      state.lazyIntercept[block] += intercept
      position = finish
    else:
      state.push(block)
      let stop = min(finish, right)
      for i in position ..< stop: state.data[i] += slope * int64(i) + intercept
      state.rebuild(block)
      position = stop

proc query(state: State, left, right: int): int64 =
  var position = left
  result = high(int64)
  while position < right:
    let block = position div BlockWidth
    let start = block * BlockWidth
    let finish = state.blockEnd(block)
    if position == start and finish <= right:
      result = min(result, state.blockMin(block))
      position = finish
    else:
      let stop = min(finish, right)
      for i in position ..< stop:
        result = min(result, state.data[i] + state.lazySlope[block] * int64(i) + state.lazyIntercept[block])
      position = stop

proc range_linear_add_range_min_benchmark*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "range_linear_add_range_min_benchmark".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  if input[0] < 1 or input[0] > MaxLength or input[1] < 1 or input[1] > MaxOperations: return -1
  let n = int(input[0])
  let q = int(input[1])
  if length < csize_t(n + 2): return -1
  var state: State
  state.n = n
  for i in 0 ..< n:
    if input[i + 2] < -1_000_000 or input[i + 2] > 1_000_000: return -1
    state.data[i] = input[i + 2]
  for block in 0 ..< (n + BlockWidth - 1) div BlockWidth: state.rebuild(block)
  var cursor = n + 2
  var checksum = 0'i64
  for operation in 0 ..< q:
    if cursor >= int(length): return -1
    let opcode = input[cursor]
    inc cursor
    if opcode == 0:
      if cursor + 4 > int(length): return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      let slope = input[cursor + 2]
      let intercept = input[cursor + 3]
      cursor += 4
      if left < 0 or left >= right or right > int64(n) or slope < -99 or slope > 99 or
          intercept < -100_000 or intercept > 100_000: return -1
      state.update(int(left), int(right), slope, intercept)
    elif opcode == 1:
      if cursor + 2 > int(length): return -1
      let left = input[cursor]
      let right = input[cursor + 1]
      cursor += 2
      if left < 0 or left >= right or right > int64(n): return -1
      checksum += int64(operation + 1) * (state.query(int(left), int(right)) + ChecksumOffset)
    else:
      return -1
  if cursor == int(length): checksum else: -1
