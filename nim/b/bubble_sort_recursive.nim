const MaxValues = 256

proc bubbleSortRecursiveImpl(values: ptr UncheckedArray[int64], length: int) =
  if length <= 1:
    return
  var swapped = false
  for index in 0 ..< length - 1:
    if values[index] > values[index + 1]:
      swap(values[index], values[index + 1])
      swapped = true
  if swapped:
    bubbleSortRecursiveImpl(values, length - 1)

proc bubble_sort_recursive*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "bubble_sort_recursive".} =
  if length <= csize_t(MaxValues):
    bubbleSortRecursiveImpl(values, int(length))
