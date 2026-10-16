const MaxUsers = 64

proc bandwidth_allocation*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bandwidth_allocation".} =
  if input.isNil or length < 2: return -1
  let bandwidth = input[0]
  let countValue = input[1]
  if bandwidth < 0 or bandwidth > 100_000 or countValue < 0 or countValue > MaxUsers: return -1
  let count = int(countValue)
  if length != csize_t(2 + 2 * count): return -1
  for index in 0 ..< count:
    let demand = input[2 + index]
    let value = input[2 + count + index]
    if demand < 1 or demand > 1_000 or value < 0 or value > 10_000: return -1

  var ratios: array[MaxUsers, float64]
  var order: array[MaxUsers, int]
  for index in 0 ..< count:
    ratios[index] = float64(input[2 + count + index]) / float64(input[2 + index])
    order[index] = index
  for index in 1 ..< count:
    let keyRatio = ratios[index]
    let keyIndex = order[index]
    var position = index
    while position > 0 and ratios[position - 1] < keyRatio:
      ratios[position] = ratios[position - 1]
      order[position] = order[position - 1]
      dec position
    ratios[position] = keyRatio
    order[position] = keyIndex

  var remaining = bandwidth
  var total: int64 = 0
  for position in 0 ..< count:
    let index = order[position]
    let demand = input[2 + index]
    let value = input[2 + count + index]
    if remaining >= demand:
      total += value
      remaining -= demand
    else:
      total += int64(ratios[position] * float64(remaining))
      break
  total
