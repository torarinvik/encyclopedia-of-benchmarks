## Count contiguous runs of equal ASCII bytes.
proc count_homogenous*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "count_homogenous".} =
  const maxTextBytes = 4096
  if input == nil or length < 1 or input[0] < 0 or input[0] > int64(maxTextBytes):
    return -1
  let count = int(input[0])
  if length != csize_t(count + 1): return -1
  for i in 0 ..< count:
    if input[1 + i] < 0 or input[1 + i] > 127: return -1
  if count == 0: return 0
  var runs = 1
  for i in 2 ..< count + 1:
    if input[i] != input[i - 1]: inc runs
  return int64(runs)
