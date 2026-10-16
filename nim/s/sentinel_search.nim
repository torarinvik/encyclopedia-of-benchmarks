## Sentinel search for the shared mutable-input benchmark contract.
proc sentinel_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "sentinel_search".} =
  if length == 0:
    return -1

  let lastIndex = length - 1
  let savedLast = values[lastIndex]
  if savedLast == target:
    return int64(lastIndex)

  values[lastIndex] = target
  var index = csize_t(0)
  while values[index] != target:
    inc index
  values[lastIndex] = savedLast

  if index == lastIndex:
    return -1
  return int64(index)
