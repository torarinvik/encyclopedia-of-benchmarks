## Count distinct positive bases whose powers sum to the target.
proc search(target, power, base, currentSum: int64): int64 =
  var term = 1'i64
  for exponent in 0'i64 ..< power:
    term *= base
  let newSum = currentSum + term
  if newSum == target:
    return 1
  if newSum > target:
    return 0
  search(target, power, base + 1, newSum) + search(target, power, base + 1, currentSum)

proc power_sum*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "power_sum".} =
  if length != 2:
    return -1
  let target = packed[0]
  let power = packed[1]
  if target < 1 or target > 1000 or power < 2 or power > 10:
    return -1
  search(target, power, 1, 0)
