const MaxValues = 1024

proc medianOfThree(first, middle, last: int64): int64 =
  if first < middle:
    if middle < last: return middle
    if first < last: return last
    return first
  if first < last: return first
  if middle < last: return last
  middle

proc quick_select*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "quick_select".} =
  if length == 0 or length > MaxValues: return -1
  var scratch: array[MaxValues, int64]
  let n = int(length)
  for index in 0 ..< n: scratch[index] = values[index]

  let target = n div 2
  var low = 0
  var high = n
  while high - low > 1:
    let middle = low + (high - low) div 2
    let pivot = medianOfThree(scratch[low], scratch[middle], scratch[high - 1])
    var less = low
    var scan = low
    var greater = high
    while scan < greater:
      if scratch[scan] < pivot:
        swap(scratch[less], scratch[scan])
        inc less
        inc scan
      elif scratch[scan] > pivot:
        dec greater
        swap(scratch[scan], scratch[greater])
      else:
        inc scan
    if target < less: high = less
    elif target >= greater: low = greater
    else: return pivot
  scratch[target]
