const MaxValidInputLength = 64
const MaxTotalSum = 4096

proc minimum_sum_partition*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_sum_partition".} =
  if length > csize_t(MaxValidInputLength) or (input.isNil and length != 0): return -1

  var total = 0'i64
  for index in 0 ..< int(length):
    let value = input[index]
    if value < 0 or value > int64(MaxTotalSum) or total > int64(MaxTotalSum) - value: return -1
    total += value

  let target = int(total div 2)
  var reachable: array[MaxTotalSum div 2 + 1, bool]
  reachable[0] = true
  var closest = 0
  for index in 0 ..< int(length):
    let value = int(input[index])
    var sum = target
    while sum > 0:
      if value <= sum and reachable[sum - value]: reachable[sum] = true
      if reachable[sum] and sum > closest: closest = sum
      dec sum
  total - 2 * int64(closest)
