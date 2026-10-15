## Sort values and grow the longest affordable window.
proc maximum_frequency_after_increments*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_frequency_after_increments".} =
  if length < 1 or length > 257 or input.isNil: return -1
  let budget = input[0]
  let count = int(length - 1)
  if budget < 0 or budget > 1_000_000: return -1
  var values: array[256, int64]
  for index in 0 ..< count:
    let value = input[index + 1]
    if value < 1 or value > 10_000: return -1
    var position = index
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value
  var left = 0
  var windowSum = 0'i64
  var best = 0
  for right in 0 ..< count:
    windowSum += values[right]
    while values[right] * int64(right - left + 1) - windowSum > budget:
      windowSum -= values[left]
      inc left
    best = max(best, right - left + 1)
  int64(best)
