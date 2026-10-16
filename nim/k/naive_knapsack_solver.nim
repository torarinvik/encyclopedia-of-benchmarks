proc naive_knapsack_solver*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "naive_knapsack_solver".} =
  if values == nil or length < 2 or length > 32: return -1
  let capacity = values[0]
  let count = values[1]
  if capacity < 0 or capacity > 1_000_000 or count < 0 or count > 30 or length != csize_t(count) + 2: return -1
  var weight = 0'i64
  var mask = 0'i64
  for i in 0 ..< int(count):
    let item = values[i + 2]
    if item < 0 or item > 1_000_000: return -1
    if weight + item <= capacity:
      weight += item
      mask = mask or (1'i64 shl i)
  mask
