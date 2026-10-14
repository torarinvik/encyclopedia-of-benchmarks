# Greedy fractional knapsack with exact fixed-point output.
proc fractional_knapsack_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "fractional_knapsack_benchmark".} =
  if length < 2 or length > 258: return -1
  let capacity = values[0]
  let itemCountValue = values[1]
  if capacity < 0 or capacity > 1000000 or itemCountValue < 0 or itemCountValue > 128: return -1
  let itemCount = int(itemCountValue)
  if int(length) != 2 + 2 * itemCount: return -1

  var weights: array[128, int64]
  var profits: array[128, int64]
  for i in 0 ..< itemCount:
    let weight = values[2 + 2 * i]
    let profit = values[3 + 2 * i]
    if weight < 1 or weight > 1000000 or profit < 0 or profit > 1000000: return -1
    weights[i] = weight
    profits[i] = profit

  for i in 1 ..< itemCount:
    let currentWeight = weights[i]
    let currentProfit = profits[i]
    var position = i
    while position > 0 and profits[position - 1] * currentWeight < currentProfit * weights[position - 1]:
      weights[position] = weights[position - 1]
      profits[position] = profits[position - 1]
      dec position
    weights[position] = currentWeight
    profits[position] = currentProfit

  var remaining = capacity
  var scaledValue: int64 = 0
  for i in 0 ..< itemCount:
    if remaining == 0: break
    if remaining >= weights[i]:
      scaledValue += profits[i] * 1000000
      remaining -= weights[i]
    else:
      scaledValue += profits[i] * remaining * 1000000 div weights[i]
      break
  scaledValue
