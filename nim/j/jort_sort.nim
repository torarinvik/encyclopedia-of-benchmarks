const MaxLength = 64

proc jort_sort*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "jort_sort".} =
  if length == 0: return 1
  if values == nil or length > MaxLength: return -1
  var copy: array[MaxLength, int64]
  for i in 0 ..< int(length): copy[i] = values[i]
  for i in 2 ..< int(length):
    let key = copy[i]
    var position = i
    while position > 1 and copy[position - 1] > key:
      copy[position] = copy[position - 1]
      dec position
    copy[position] = key
  for i in 0 ..< int(length):
    if copy[i] != values[i]: return 0
  1
