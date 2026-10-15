proc lower_bound_range(values: ptr UncheckedArray[int64], target: int64,
                       left: int64, right: int64): int64 =
  if right <= left:
    return left
  let middle = (left + right) div 2
  if target == values[middle]:
    return middle
  if target < values[middle]:
    return lower_bound_range(values, target, left, middle)
  return lower_bound_range(values, target, middle + 1, right)

proc lower_bound*(values: ptr UncheckedArray[int64], length: csize_t,
                  target: int64): int64 {.cdecl, exportc: "lower_bound".} =
  if length > 512 or target < int64(low(int32)) or target > int64(high(int32)):
    return -1
  if length > 0 and values == nil:
    return -1
  for i in 0 ..< int(length):
    if values[i] < int64(low(int32)) or values[i] > int64(high(int32)):
      return -1
    if i > 0 and values[i - 1] > values[i]:
      return -1
  return lower_bound_range(values, target, 0, int64(length) - 1)
