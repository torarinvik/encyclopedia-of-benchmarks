const MaxIntervals = 64
const MaxInputLength = 193

type I64Array = ptr UncheckedArray[int64]
type ByteArray = ptr UncheckedArray[uint8]
type IndexArray = array[MaxIntervals, int]
type DpArray = array[MaxIntervals + 1, int64]

proc startAt(input: I64Array, index: int): int64 = input[1 + index * 3]
proc endAt(input: I64Array, index: int): int64 = input[2 + index * 3]
proc weightAt(input: I64Array, index: int): int64 = input[3 + index * 3]

proc storeI64Le(output: ByteArray, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)
proc storeI32Le(output: ByteArray, offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc weighted_interval_scheduling*(input: I64Array, length: csize_t, output: ByteArray, capacity: csize_t): int64
    {.cdecl, exportc: "weighted_interval_scheduling".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength) or input[0] < 0 or input[0] > MaxIntervals: return -1
  let n = int(input[0])
  if length != csize_t(1 + 3 * n): return -1
  for i in 0 ..< n:
    let start = startAt(input, i)
    let finish = endAt(input, i)
    let weight = weightAt(input, i)
    if start < -100_000 or start > 100_000 or finish < -100_000 or finish > 100_000 or start >= finish or weight < 0 or weight > 1_000_000: return -1
  var order: IndexArray
  var predecessors: IndexArray
  var selected: IndexArray
  var dp: DpArray
  for i in 0 ..< n: order[i] = i
  for i in 1 ..< n:
    let key = order[i]
    var j = i
    while j > 0 and endAt(input, order[j - 1]) > endAt(input, key):
      order[j] = order[j - 1]
      dec j
    order[j] = key
  for j in 0 ..< n:
    var low = 0
    var high = n
    while low < high:
      let mid = low + (high - low) div 2
      if endAt(input, order[mid]) <= startAt(input, order[j]): low = mid + 1
      else: high = mid
    predecessors[j] = low
    let include = weightAt(input, order[j]) + dp[low]
    dp[j + 1] = if include > dp[j]: include else: dp[j]
  var selectedCount = 0
  var current = n
  while current > 0:
    let j = current - 1
    let include = weightAt(input, order[j]) + dp[predecessors[j]]
    if include > dp[current - 1]:
      selected[selectedCount] = order[j]
      inc selectedCount
      current = predecessors[j]
    else: dec current
  if selectedCount > 1:
    for i in 0 ..< selectedCount div 2: swap(selected[i], selected[selectedCount - 1 - i])
  let needed = 16 + 4 * selectedCount
  if output.isNil or capacity < csize_t(needed): return -2
  storeI64Le(output, 0, dp[n])
  storeI64Le(output, 8, int64(selectedCount))
  for i in 0 ..< selectedCount: storeI32Le(output, 16 + 4 * i, int32(selected[i]))
  int64(needed)
