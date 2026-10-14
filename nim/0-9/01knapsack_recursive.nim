const MaxCapacity = 512'i64
const MaxItems = 16'i64
const MaxWeight = 4096'i64
const MaxValue = 1_000_000_000'i64

proc solve(packed: ptr UncheckedArray[int64], itemCount, capacity: int64): int64 =
  if itemCount == 0 or capacity == 0:
    return 0
  let offset = 2 + 2 * (itemCount - 1)
  let weight = packed[offset]
  let value = packed[offset + 1]
  if weight <= capacity:
    let take = value + solve(packed, itemCount - 1, capacity - weight)
    let skip = solve(packed, itemCount - 1, capacity)
    return max(take, skip)
  return solve(packed, itemCount - 1, capacity)

proc knapsack_01_recursive_benchmark*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "knapsack_01_recursive_benchmark".} =
  if length < 2 or length > 34:
    return -1
  let capacity = packed[0]
  let itemCount = packed[1]
  if capacity < 0 or capacity > MaxCapacity or itemCount < 0 or itemCount > MaxItems or length.int != 2 + 2 * itemCount.int:
    return -1
  for item in 0 ..< itemCount.int:
    let offset = 2 + 2 * item
    if packed[offset] < 1 or packed[offset] > MaxWeight or packed[offset + 1] < 0 or packed[offset + 1] > MaxValue:
      return -1
  solve(packed, itemCount, capacity)
