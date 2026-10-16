proc upper_bound_range(values: ptr UncheckedArray[int64], target: int64,
                       left: int64, right: int64): int64 =
  if right <= left:
    return left
  let middle = (left + right) div 2
  if target < values[middle + 1]:
    return upper_bound_range(values, target, left, middle)
  return upper_bound_range(values, target, middle + 1, right)

proc upper_bound*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "upper_bound".} =
  if values == nil or length == 0 or length > 513:
    return -1
  let target = values[0]
  if target < int64(low(int32)) or target > int64(high(int32)):
    return -1
  let arrayLength = int(length - 1)
  for i in 0 ..< arrayLength:
    let value = values[i + 1]
    if value < int64(low(int32)) or value > int64(high(int32)):
      return -1
    if i > 0 and values[i] > value:
      return -1
  return upper_bound_range(values, target, 0, int64(arrayLength) - 1)
