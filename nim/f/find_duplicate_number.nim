## Find the cycle entrance induced by the duplicate value.
proc find_duplicate_number*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "find_duplicate_number".} =
  if length < 2 or length > 100001:
    return -1
  let maximumValue = length - 1
  for index in 0 ..< length:
    if values[index] < 1 or uint64(values[index]) > uint64(maximumValue):
      return -1

  var slow = csize_t(values[0])
  var fast = slow
  while true:
    slow = csize_t(values[slow])
    fast = csize_t(values[csize_t(values[fast])])
    if slow == fast:
      break

  slow = csize_t(values[0])
  while slow != fast:
    slow = csize_t(values[slow])
    fast = csize_t(values[fast])
  int64(slow)
