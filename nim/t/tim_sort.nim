## Stable bottom-up TimSort-style sort using caller-provided scratch storage.
const TimSortRun = csize_t(32)

proc insertion_sort_run(values: ptr UncheckedArray[int64], low, high: csize_t) =
  var index = low + 1
  while index < high:
    let key = values[index]
    var cursor = index
    while cursor > low and values[cursor - 1] > key:
      values[cursor] = values[cursor - 1]
      dec cursor
    values[cursor] = key
    inc index

proc merge_runs(values, scratch: ptr UncheckedArray[int64], left, middle, right: csize_t) =
  for index in left ..< right:
    scratch[index] = values[index]
  var first = left
  var second = middle
  var output = left
  while output < right:
    if first == middle:
      values[output] = scratch[second]
      inc second
    elif second == right or scratch[first] <= scratch[second]:
      values[output] = scratch[first]
      inc first
    else:
      values[output] = scratch[second]
      inc second
    inc output

proc tim_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "tim_sort".} =
  if length < 2:
    return
  var start = csize_t(0)
  while start < length:
    let remaining = length - start
    let ending = if remaining < TimSortRun: length else: start + TimSortRun
    insertion_sort_run(values, start, ending)
    start = ending

  var width = TimSortRun
  while width < length:
    var left = csize_t(0)
    while left < length:
      let leftRemaining = length - left
      let middle = left + (if width < leftRemaining: width else: leftRemaining)
      let rightRemaining = length - middle
      let right = middle + (if width < rightRemaining: width else: rightRemaining)
      if middle < right:
        merge_runs(values, scratch, left, middle, right)
      left = right
    if width >= length - width:
      break
    width *= 2
