proc medianOfThree(a, b, c: int64): int64 =
  if a <= b:
    if b <= c: return b
    if a <= c: return c
    return a
  if b >= c: return b
  if a >= c: return c
  a

proc partitionRange(values: ptr UncheckedArray[int64], left, right: csize_t): csize_t =
  let middle = left + (right - left) div 2
  let pivot = medianOfThree(values[left], values[middle], values[right])
  var nleft = left
  var nright = right
  while true:
    while values[nleft] < pivot: inc nleft
    while values[nright] > pivot: dec nright
    if nleft >= nright: return nright
    swap(values[nleft], values[nright])
    inc nleft
    dec nright

proc sortRange(values: ptr UncheckedArray[int64], left, right: csize_t) =
  if left >= right: return
  let pivot = partitionRange(values, left, right)
  sortRange(values, left, pivot)
  sortRange(values, pivot + 1, right)

proc median_of_three_quick_sorter*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "median_of_three_quick_sorter".} =
  if length > 1:
    sortRange(values, 0, length - 1)
