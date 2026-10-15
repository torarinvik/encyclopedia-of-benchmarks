## Find the least positive divisor whose rounded sum fits the threshold.
proc smallest_divisor*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "smallest_divisor".} =
  if length < 2 or length > 257 or input.isNil: return -1
  let threshold = input[0]
  if threshold < 1 or threshold > 1_000_000: return -1
  var maximum = 0'i64
  for index in 1 ..< int(length):
    let value = input[index]
    if value < 1 or value > 1_000_000: return -1
    if value > maximum: maximum = value
  let count = int64(length - 1)
  if threshold < count: return -1
  var low = 1'i64
  var high = maximum
  while low < high:
    let middle = low + (high - low) div 2
    var sum = 0'i64
    for index in 1 ..< int(length):
      sum += (input[index] + middle - 1) div middle
    if sum <= threshold: high = middle
    else: low = middle + 1
  low
