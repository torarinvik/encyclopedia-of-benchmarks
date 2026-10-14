## Interpolation search in an ascending sequence for the shared benchmark contract.
proc interpolation_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "interpolation_search".} =
  if length == 0:
    return -1
  var low = csize_t(0)
  var high = length - 1
  while low <= high:
    let lowValue = values[low]
    let highValue = values[high]
    if target < lowValue or target > highValue:
      return -1
    if lowValue == highValue:
      if lowValue == target:
        return int64(low)
      return -1
    let numerator = (target - lowValue) * int64(high - low)
    let denominator = highValue - lowValue
    let position = low + csize_t(numerator div denominator)
    let value = values[position]
    if value == target:
      return int64(position)
    if value < target:
      low = position + 1
    else:
      if position == 0:
        return -1
      high = position - 1
  return -1
