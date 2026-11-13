const
  MaxN = 16
  MaxEvents = 32
  MaxQueries = 32
  MaxParseableLength = 196

proc bitAdd(bit: var openArray[int64], start: int, delta: int64, limit: int) =
  var index = start
  while index <= limit + 1:
    bit[index] += delta
    index += index and -index

proc bitSum(bit: openArray[int64], start: int): int64 =
  var index = start
  var total = 0'i64
  while index > 0:
    total += bit[index]
    index -= index and -index
  total

proc rangeAdd(bit1, bit2: var openArray[int64], n, left, right: int, delta: int64) =
  let lo = left + 1
  let hi = right + 1
  bitAdd(bit1, lo, delta, n)
  bitAdd(bit1, hi + 1, -delta, n)
  bitAdd(bit2, lo, delta * int64(lo - 1), n)
  bitAdd(bit2, hi + 1, -delta * int64(hi), n)

proc prefixSum(bit1, bit2: openArray[int64], count: int): int64 =
  int64(count) * bitSum(bit1, count) - bitSum(bit2, count)

proc rangeSum(bit1, bit2: openArray[int64], left, right: int): int64 =
  prefixSum(bit1, bit2, right + 1) - prefixSum(bit1, bit2, left)

proc parallel_binary_search_range_threshold*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "parallel_binary_search_range_threshold".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxParseableLength): return -1
  if input[0] < 1 or input[0] > int64(MaxN) or input[1] < 0 or input[1] > int64(MaxEvents) or
      input[2] < 0 or input[2] > int64(MaxQueries): return -1
  let n = int(input[0])
  let eventCount = int(input[1])
  let queryCount = int(input[2])
  if int(length) != 3 + 3 * eventCount + 3 * queryCount: return -1

  var eventLeft: array[MaxEvents, int]
  var eventRight: array[MaxEvents, int]
  var eventDelta: array[MaxEvents, int64]
  var queryLeft: array[MaxQueries, int]
  var queryRight: array[MaxQueries, int]
  var queryTarget: array[MaxQueries, int64]
  var cursor = 3
  for event in 0 ..< eventCount:
    let leftValue = input[cursor]
    let rightValue = input[cursor + 1]
    let delta = input[cursor + 2]
    cursor += 3
    if leftValue < 0 or leftValue > rightValue or rightValue >= int64(n) or delta < 0 or delta > 1000: return -1
    eventLeft[event] = int(leftValue)
    eventRight[event] = int(rightValue)
    eventDelta[event] = delta
  for query in 0 ..< queryCount:
    let leftValue = input[cursor]
    let rightValue = input[cursor + 1]
    let target = input[cursor + 2]
    cursor += 3
    if leftValue < 0 or leftValue > rightValue or rightValue >= int64(n) or target < 1 or target > 512000: return -1
    queryLeft[query] = int(leftValue)
    queryRight[query] = int(rightValue)
    queryTarget[query] = target

  var low: array[MaxQueries, int64]
  var high: array[MaxQueries, int64]
  var nextQuery: array[MaxQueries, int64]
  for query in 0 ..< queryCount:
    high[query] = int64(eventCount + 1)

  while true:
    var heads: array[MaxEvents + 1, int64]
    for time in 0 .. MaxEvents: heads[time] = -1
    for query in 0 ..< queryCount: nextQuery[query] = -1
    var active = false
    for query in 0 ..< queryCount:
      if high[query] - low[query] > 1:
        active = true
        let middle = int((low[query] + high[query]) div 2)
        nextQuery[query] = heads[middle]
        heads[middle] = int64(query)
    if not active: break

    var bit1: array[MaxN + 2, int64]
    var bit2: array[MaxN + 2, int64]
    var applied = 0
    for middle in 0 .. eventCount:
      while applied < middle:
        rangeAdd(bit1, bit2, n, eventLeft[applied], eventRight[applied], eventDelta[applied])
        inc applied
      var query = heads[middle]
      while query >= 0:
        let id = int(query)
        if rangeSum(bit1, bit2, queryLeft[id], queryRight[id]) >= queryTarget[id]:
          high[id] = int64(middle)
        else:
          low[id] = int64(middle)
        query = nextQuery[id]

  result = 0'i64
  for query in 0 ..< queryCount:
    result += int64(query + 1) * (high[query] + 1)
  result
