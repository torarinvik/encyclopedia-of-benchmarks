const MaxValues = 1024

proc merge_sort_nr*(values: ptr UncheckedArray[int64], length: csize_t)
    {.cdecl, exportc: "merge_sort_nr".} =
  if length > csize_t(MaxValues):
    return
  let n = int(length)
  var scratch: array[MaxValues, int64]
  var width = 1
  while width < n:
    var start = 0
    while start < n:
      let middle = min(start + width, n)
      let endIndex = min(middle + width, n)
      var left = start
      var right = middle
      var output = start
      while left < middle and right < endIndex:
        if values[left] <= values[right]:
          scratch[output] = values[left]
          inc left
        else:
          scratch[output] = values[right]
          inc right
        inc output
      while left < middle:
        scratch[output] = values[left]
        inc left
        inc output
      while right < endIndex:
        scratch[output] = values[right]
        inc right
        inc output
      start += width * 2
    for index in 0 ..< n:
      values[index] = scratch[index]
    width *= 2
