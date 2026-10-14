## Ternary search in an ascending sequence for the shared benchmark contract.
proc ternary_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "ternary_search".} =
  var low = csize_t(0)
  var high = length
  while low < high:
    let third = (high - low) div 3
    let first = low + third
    let second = high - third - 1
    let firstValue = values[first]
    let secondValue = values[second]
    if firstValue == target:
      return int64(first)
    if secondValue == target:
      return int64(second)
    if target < firstValue:
      high = first
    elif target > secondValue:
      low = second + 1
    else:
      low = first + 1
      high = second
  return -1
