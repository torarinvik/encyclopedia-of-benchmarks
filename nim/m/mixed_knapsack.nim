const MaxTypes = 16
const MaxCapacity = 64
const MaxInput = 67

proc mixed_knapsack*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "mixed_knapsack".} =
  if input.isNil or length < 2 or length > MaxInput:
    return -1
  let typeCountValue = input[0]
  let capacityValue = input[1]
  if typeCountValue < 0 or typeCountValue > MaxTypes or capacityValue < 0 or capacityValue > MaxCapacity:
    return -1
  let typeCount = int(typeCountValue)
  let capacity = int(capacityValue)
  if int(length) != 2 + 4 * typeCount:
    return -1
  for item in 0 ..< typeCount:
    let mode = input[2 + 4 * item]
    let weight = input[3 + 4 * item]
    let value = input[4 + 4 * item]
    let limit = input[5 + 4 * item]
    if mode < 0 or mode > 2 or weight < 1 or weight > 16 or value < 0 or value > 100:
      return -1
    if (mode == 0 and limit != 1) or (mode == 1 and limit != 0) or
       (mode == 2 and (limit < 0 or limit > 16)):
      return -1

  var best: array[65, int64]
  for item in 0 ..< typeCount:
    let mode = input[2 + 4 * item]
    let weight = int(input[3 + 4 * item])
    let value = input[4 + 4 * item]
    if mode == 0:
      var cap = capacity
      while cap >= weight:
        best[cap] = max(best[cap], best[cap - weight] + value)
        if cap == weight:
          break
        dec cap
    elif mode == 1:
      for cap in weight .. capacity:
        best[cap] = max(best[cap], best[cap - weight] + value)
    else:
      var remaining = int(input[5 + 4 * item])
      var bundleSize = 1
      while remaining > 0:
        let copies = min(bundleSize, remaining)
        let bundleWeight = copies * weight
        let bundleValue = int64(copies) * value
        if bundleWeight <= capacity:
          var cap = capacity
          while cap >= bundleWeight:
            best[cap] = max(best[cap], best[cap - bundleWeight] + bundleValue)
            if cap == bundleWeight:
              break
            dec cap
        remaining -= copies
        bundleSize *= 2
  best[capacity]
