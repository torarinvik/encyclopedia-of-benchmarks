## First-element-pivot quicksort using Hoare's partition scheme.
proc partitionRange(values: ptr UncheckedArray[int64], low, high: csize_t): csize_t =
  let pivot = values[low]
  var left = low
  var right = high
  while true:
    while values[left] < pivot: inc left
    while values[right] > pivot: dec right
    if left >= right: return right
    swap(values[left], values[right])
    inc left
    dec right

proc partitionSortRange(values: ptr UncheckedArray[int64], low, high: csize_t) =
  if low < high:
    let split = partitionRange(values, low, high)
    partitionSortRange(values, low, split)
    partitionSortRange(values, split + 1, high)

proc partition_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "partition_sort".} =
  if length > 1:
    partitionSortRange(values, 0, length - 1)
