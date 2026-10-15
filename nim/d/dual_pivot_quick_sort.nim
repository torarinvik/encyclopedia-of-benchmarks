proc dualPivotSortRange(values: ptr UncheckedArray[int64], lowValue, highValue: csize_t) =
  var low = lowValue
  var high = highValue
  while high - low > 2:
    if values[low] > values[high - 1]:
      swap(values[low], values[high - 1])
    let pivot1 = values[low]
    let pivot2 = values[high - 1]
    var less = low + 1
    var scan = low + 1
    var greater = high - 2
    while scan <= greater:
      if values[scan] < pivot1:
        swap(values[scan], values[less])
        inc less
      elif values[scan] >= pivot2:
        while scan < greater and values[greater] > pivot2:
          dec greater
        swap(values[scan], values[greater])
        dec greater
        if values[scan] < pivot1:
          swap(values[scan], values[less])
          inc less
      inc scan
    let pivot1Index = less - 1
    let pivot2Index = greater + 1
    swap(values[low], values[pivot1Index])
    swap(values[high - 1], values[pivot2Index])
    let leftSize = pivot1Index - low
    let middleSize = pivot2Index - pivot1Index - 1
    let rightSize = high - pivot2Index - 1
    if leftSize >= middleSize and leftSize >= rightSize:
      dualPivotSortRange(values, pivot1Index + 1, pivot2Index)
      dualPivotSortRange(values, pivot2Index + 1, high)
      high = pivot1Index
    elif middleSize >= rightSize:
      dualPivotSortRange(values, low, pivot1Index)
      dualPivotSortRange(values, pivot2Index + 1, high)
      low = pivot1Index + 1
      high = pivot2Index
    else:
      dualPivotSortRange(values, low, pivot1Index)
      dualPivotSortRange(values, pivot1Index + 1, pivot2Index)
      low = pivot2Index + 1
  if high - low == 2 and values[low] > values[low + 1]:
    swap(values[low], values[low + 1])

proc dual_pivot_quick_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "dual_pivot_quick_sort".} =
  if length > 1:
    dualPivotSortRange(values, 0, length)
