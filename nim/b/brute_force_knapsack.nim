proc solve(packed: ptr UncheckedArray[int64], itemCount: int, capacity: int64): int64 =
  if itemCount == 0 or capacity == 0: return 0
  let weight = packed[2 + 2 * (itemCount - 1)]
  let value = packed[3 + 2 * (itemCount - 1)]
  if weight > capacity: return solve(packed, itemCount - 1, capacity)
  let excluded = solve(packed, itemCount - 1, capacity)
  let included = value + solve(packed, itemCount - 1, capacity - weight)
  max(excluded, included)

proc brute_force_knapsack*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "brute_force_knapsack".} =
  if packed.isNil or length < 2 or length > 30: return -1
  let capacity = packed[0]
  let countValue = packed[1]
  if capacity < 0 or capacity > 512 or countValue < 0 or countValue > 14: return -1
  let itemCount = int(countValue)
  if int(length) != 2 + 2 * itemCount: return -1
  for item in 0 ..< itemCount:
    let weight = packed[2 + 2 * item]
    let value = packed[3 + 2 * item]
    if weight < 1 or weight > 4096 or value < 0 or value > 100_000_000: return -1
  solve(packed, itemCount, capacity)
