## Recursive circle sort for the shared signed 64-bit benchmark contract.
proc circle_pass(values: ptr UncheckedArray[int64], low, high: csize_t): bool =
  let length = high - low
  if length < 2:
    return false
  var swapped = false
  var left = low
  var right = high - 1
  while left < right:
    if values[left] > values[right]:
      let temporary = values[left]
      values[left] = values[right]
      values[right] = temporary
      swapped = true
    inc left
    dec right
  if length mod 2 != 0 and left == right and right + 1 < high and values[right + 1] < values[right]:
    let temporary = values[right]
    values[right] = values[right + 1]
    values[right + 1] = temporary
    swapped = true
  let split = low + length div 2 + length mod 2
  let leftSwapped = circle_pass(values, low, split)
  let rightSwapped = circle_pass(values, split, high)
  return swapped or leftSwapped or rightSwapped

proc circle_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "circle_sort".} =
  while length > 1 and circle_pass(values, 0, length):
    discard
