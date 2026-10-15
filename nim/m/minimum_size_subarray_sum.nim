proc minimum_size_subarray_sum*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "minimum_size_subarray_sum".} =
  if length < 2:
    return -1
  let target = packed[0]
  let count = packed[1]
  if target < 1 or target > 1_000_000 or count < 0 or count > 256 or length != csize_t(count) + 2:
    return -1
  for index in 0'i64 ..< count:
    let value = packed[index + 2]
    if value < 1 or value > 1_000_000:
      return -1
  var left = 0'i64
  var currentSum = 0'i64
  var best = count + 1
  for right in 0'i64 ..< count:
    currentSum += packed[right + 2]
    while currentSum >= target:
      let width = right - left + 1
      if width < best:
        best = width
      currentSum -= packed[left + 2]
      inc left
  if best <= count: best else: 0
