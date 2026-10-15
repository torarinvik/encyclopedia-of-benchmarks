proc circleSortRange(values: ptr UncheckedArray[int64], leftValue, rightValue: csize_t): bool =
  if leftValue >= rightValue:
    return false

  var low = leftValue
  var high = rightValue
  var swapped = false
  while low < high:
    if values[low] > values[high]:
      swap(values[low], values[high])
      swapped = true
    inc low
    dec high
  if low == high and values[low] > values[high + 1]:
    swap(values[low], values[high + 1])
    swapped = true

  let middle = leftValue + (rightValue - leftValue) div 2
  let leftSwapped = circleSortRange(values, leftValue, middle)
  let rightSwapped = circleSortRange(values, middle + 1, rightValue)
  swapped or leftSwapped or rightSwapped

proc circle_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "circle_sort".} =
  if length < 2:
    return
  while circleSortRange(values, 0, length - 1):
    discard
