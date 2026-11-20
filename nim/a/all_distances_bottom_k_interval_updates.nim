const MAX_N = 32
const MAX_K = 4
const MAX_INPUT = 99
const MAX_WORDS = 97
const DISTANCE_LIMIT = 1_000_000'i64
const END_SENTINEL = 1_000_001'i64

type Interval = object
  itemId, rank, first, past: int64

proc putI64(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[8 * word + byte] = uint8((bits shr (8 * byte)) and 255)

proc all_distances_bottom_k_interval_updates*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"all_distances_bottom_k_interval_updates".} =
  if input == nil or length < 2 or length > MAX_INPUT: return -1
  let n0 = input[0]
  let k0 = input[1]
  if n0 < 2 or n0 > MAX_N or k0 < 2 or k0 > MAX_K or k0 > n0: return -1
  let n = int(n0)
  let k = int(k0)
  if int(length) != 2 + 3 * n: return -1

  var records: array[MAX_N, Interval]
  var seenIds: array[MAX_N, bool]
  var seenRanks: array[MAX_N, bool]
  for i in 0..<n:
    let id = input[2 + 3 * i]
    let distance = input[3 + 3 * i]
    let rank = input[4 + 3 * i]
    if id < 0 or id >= n0 or seenIds[int(id)] or rank < 0 or rank >= n0
        or seenRanks[int(rank)] or distance < 0 or distance > DISTANCE_LIMIT: return -1
    seenIds[int(id)] = true
    seenRanks[int(rank)] = true
    for j in 0..<i:
      if records[j].first == distance: return -1
    records[i] = Interval(itemId: id, rank: rank, first: distance, past: 0)
  for i in 1..<k:
    if records[i - 1].first >= records[i].first: return -1
  for i in k..<n:
    if records[i].first <= records[k - 1].first: return -1

  var intervals: array[MAX_N, Interval]
  var count = k
  for i in 0..<k:
    intervals[i] = Interval(itemId: records[i].itemId, rank: records[i].rank,
                             first: records[i].first, past: END_SENTINEL)
  for i in k..<n:
    var worst = MAX_N
    var active = 0
    for j in 0..<count:
      if intervals[j].first <= records[i].first and records[i].first < intervals[j].past:
        inc active
        if worst == MAX_N or intervals[j].rank > intervals[worst].rank: worst = j
    if active != k or worst == MAX_N: return -1
    if records[i].rank >= intervals[worst].rank: continue
    var cursor = intervals[worst].past
    intervals[worst].past = records[i].first
    while cursor < END_SENTINEL:
      var nextWorst = MAX_N
      for j in 0..<count:
        if intervals[j].first <= cursor and cursor < intervals[j].past
            and (nextWorst == MAX_N or intervals[j].rank > intervals[nextWorst].rank):
          nextWorst = j
      if nextWorst == MAX_N or intervals[nextWorst].rank <= records[i].rank: break
      let nextCursor = intervals[nextWorst].past
      intervals[nextWorst].past = cursor
      cursor = nextCursor
    intervals[count] = Interval(itemId: records[i].itemId, rank: records[i].rank,
                                first: records[i].first, past: cursor)
    inc count

  var order: array[MAX_N, int]
  var outCount = 0
  for i in 0..<count:
    if intervals[i].first < intervals[i].past:
      order[outCount] = i
      inc outCount
  for i in 1..<outCount:
    let key = order[i]
    var j = i
    while j > 0 and (intervals[order[j - 1]].first > intervals[key].first
        or (intervals[order[j - 1]].first == intervals[key].first
            and intervals[order[j - 1]].itemId > intervals[key].itemId)):
      order[j] = order[j - 1]
      dec j
    order[j] = key

  var staged: array[MAX_WORDS, int64]
  staged[0] = int64(outCount)
  for i in 0..<outCount:
    let entry = intervals[order[i]]
    staged[1 + 3 * i] = entry.itemId
    staged[2 + 3 * i] = entry.first
    staged[3 + 3 * i] = entry.past
  let bytes = 8 * (1 + 3 * outCount)
  if output == nil or capacity < csize_t(bytes): return -2
  for word in 0..<(1 + 3 * outCount): putI64(output, word, staged[word])
  int64(bytes)
