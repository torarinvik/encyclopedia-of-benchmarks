## Jump search in an ascending sequence for the shared benchmark contract.
proc integerSqrt(value: csize_t): csize_t =
  if value < 2:
    return value
  var low = csize_t(1)
  var high = value div 2 + 1
  var result = csize_t(1)
  while low <= high:
    let middle = low + (high - low) div 2
    if middle <= value div middle:
      result = middle
      low = middle + 1
    else:
      high = middle - 1
  return result

proc jump_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "jump_search".} =
  if length == 0:
    return -1
  let step = max(csize_t(1), integerSqrt(length))
  var blockStart = csize_t(0)
  var blockEnd = min(step, length)
  while values[blockEnd - 1] < target:
    if blockEnd == length:
      return -1
    blockStart = blockEnd
    blockEnd = if step > length - blockEnd: length else: blockEnd + step
  var index = blockStart
  while index < blockEnd:
    if values[index] == target:
      return int64(index)
    if values[index] > target:
      return -1
    inc index
  return -1
