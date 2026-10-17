## Bottom-up 0/1 knapsack using one row and descending capacities.
proc knapsack_zero_one_tabulation*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "knapsack_zero_one_tabulation".} =
  if packed == nil or length < 2 or length > 258:
    return -1
  if packed[0] < 0 or packed[0] > 512 or packed[1] < 0 or packed[1] > 128:
    return -1
  let capacity = int(packed[0])
  let itemCount = int(packed[1])
  if length != csize_t(2 + 2 * itemCount):
    return -1
  for item in 0 ..< itemCount:
    let weight = packed[2 + 2 * item]
    let value = packed[3 + 2 * item]
    if weight < 1 or weight > 4096 or value < 0 or value > 1_000_000_000:
      return -1

  var dp: array[513, int64]
  let width = capacity + 1
  let steps = itemCount * width
  for step in 0 ..< steps:
    let item = step div width
    let currentCapacity = capacity - step mod width
    let weight = int(packed[2 + 2 * item])
    let value = packed[3 + 2 * item]
    if weight <= currentCapacity:
      let candidate = dp[currentCapacity - weight] + value
      if candidate > dp[currentCapacity]:
        dp[currentCapacity] = candidate
  dp[capacity]
