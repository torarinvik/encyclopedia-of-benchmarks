const MaxTypes = 16
const MaxCapacity = 64
const MaxInput = 51

proc bounded_knapsack_binary_grouping*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bounded_knapsack_binary_grouping".} =
  if input.isNil or length < 2 or length > MaxInput:
    return -1
  let typeCountValue = input[0]
  let capacityValue = input[1]
  if typeCountValue < 0 or typeCountValue > MaxTypes or capacityValue < 0 or capacityValue > MaxCapacity:
    return -1
  let typeCount = int(typeCountValue)
  let capacity = int(capacityValue)
  if int(length) != 2 + 3 * typeCount:
    return -1
  for item in 0 ..< typeCount:
    let weight = input[2 + 3 * item]
    let value = input[3 + 3 * item]
    let count = input[4 + 3 * item]
    if weight < 1 or weight > 16 or value < 0 or value > 100 or count < 0 or count > 16:
      return -1

  var best: array[65, int64]
  for item in 0 ..< typeCount:
    let weight = int(input[2 + 3 * item])
    let value = input[3 + 3 * item]
    var remaining = int(input[4 + 3 * item])
    var bundleSize = 1
    while remaining > 0:
      let copies = min(bundleSize, remaining)
      let bundleWeight = weight * copies
      let bundleValue = value * int64(copies)
      if bundleWeight <= capacity:
        var limit = capacity
        while limit >= bundleWeight:
          best[limit] = max(best[limit], best[limit - bundleWeight] + bundleValue)
          if limit == bundleWeight:
            break
          dec limit
      remaining -= copies
      bundleSize *= 2
  best[capacity]
