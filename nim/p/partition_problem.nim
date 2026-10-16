## Equal-sum two-way partition using bottom-up subset-sum reachability.
const MaxItems = 16
const MaxTotal = 1024

proc partition_problem*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "partition_problem".} =
  if input.isNil or length == 0 or length > csize_t(MaxItems): return -1
  var total = 0'i64
  for index in 0 ..< int(length):
    let value = input[index]
    if value < 0 or value > 256 or total > int64(MaxTotal) - value: return -1
    total += value
  if (total and 1) != 0: return 0
  let target = int(total div 2)
  var reachable: array[MaxTotal + 1, bool]
  reachable[0] = true
  for index in 0 ..< int(length):
    let value = int(input[index])
    if value <= target:
      var sum = target
      while sum >= value:
        if reachable[sum - value]: reachable[sum] = true
        if sum == value: break
        dec sum
  int64(reachable[target])
