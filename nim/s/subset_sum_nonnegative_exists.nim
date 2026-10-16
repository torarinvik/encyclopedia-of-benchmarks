## Nonnegative subset existence with descending dynamic programming.
const MaxItems = 64
const MaxTarget = 4096'i64
const Width = 4097

proc subset_sum_nonnegative_exists*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subset_sum_nonnegative_exists".} =
  if input.isNil or length == 0 or length > csize_t(MaxItems + 1): return -1
  let target = input[0]
  if target < 0 or target > MaxTarget: return -1
  for index in 1 ..< int(length):
    if input[index] < 0 or input[index] > MaxTarget: return -1

  var reachable: array[Width, bool]
  reachable[0] = true
  for index in 1 ..< int(length):
    let item = input[index]
    var sum = target
    while sum >= item:
      if reachable[int(sum - item)]: reachable[int(sum)] = true
      dec sum
  if reachable[int(target)]: 1 else: 0
