## Dutch national flag sort for values restricted to 0, 1, and 2.
proc dutch_national_flag_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "dutch_national_flag_sort".} =
  var low = csize_t(0)
  var middle = csize_t(0)
  var high = length
  while middle < high:
    if values[middle] == 0:
      let temporary = values[low]
      values[low] = values[middle]
      values[middle] = temporary
      inc low
      inc middle
    elif values[middle] == 1:
      inc middle
    else:
      dec high
      let temporary = values[middle]
      values[middle] = values[high]
      values[high] = temporary
