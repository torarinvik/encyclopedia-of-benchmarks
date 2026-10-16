## Port of TheAlgorithms/Java IterativeTernarySearch interval updates.
proc iterative_ternary_search*(packed: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "iterative_ternary_search".} =
  if length < 2:
    return -1
  let target = packed[0]
  let arrayLength = length - 1
  if arrayLength == 1:
    return if packed[1] == target: 0 else: -1
  var left = csize_t(0)
  var right = arrayLength - 1
  while right > left:
    if packed[left + 1] == target:
      return int64(left)
    if packed[right + 1] == target:
      return int64(right)
    let leftThird = left + (right - left) div 3 + 1
    let rightThird = right - (right - left) div 3 - 1
    if packed[leftThird + 1] <= target:
      left = leftThird
    else:
      right = rightThird
  return -1
