## Count strict inversions with bottom-up merge sort.
proc count_inversions*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "count_inversions".} =
  const maxLength = 4096
  if length > maxLength or (length > 0 and values == nil): return -1
  if length < 2: return 0
  var source: array[maxLength, int64]
  var scratch: array[maxLength, int64]
  for i in 0 ..< int(length): source[i] = values[i]

  var inversions = 0'i64
  var width = 1
  while width < int(length):
    var low = 0
    while low < int(length):
      let middle = min(low + width, int(length))
      let high = min(middle + width, int(length))
      var left = low
      var right = middle
      var output = low
      while left < middle and right < high:
        if source[left] <= source[right]:
          scratch[output] = source[left]
          inc left
        else:
          scratch[output] = source[right]
          inc right
          inversions += int64(middle - left)
        inc output
      while left < middle:
        scratch[output] = source[left]
        inc left
        inc output
      while right < high:
        scratch[output] = source[right]
        inc right
        inc output
      low = high
    for i in 0 ..< int(length): source[i] = scratch[i]
    width *= 2
  return inversions
