const MaxValues = 1024

proc cocktail_selection_sort*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "cocktail_selection_sort".} =
  if length > csize_t(MaxValues):
    return
  var low = 0
  var high = int(length)
  while high - low > 1:
    var minimumIndex = low
    var maximumIndex = low
    for index in low + 1 ..< high:
      if values[index] < values[minimumIndex]:
        minimumIndex = index
      if values[index] > values[maximumIndex]:
        maximumIndex = index
    swap(values[minimumIndex], values[low])
    if maximumIndex == low:
      maximumIndex = minimumIndex
    swap(values[maximumIndex], values[high - 1])
    inc low
    dec high
