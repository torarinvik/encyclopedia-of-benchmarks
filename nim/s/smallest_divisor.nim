## Find the least positive divisor whose rounded sum fits the threshold.
proc smallest_divisor*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "smallest_divisor".} =
  if length < 2 or length > 257 or input.isNil: return -1
  let count = uint64(length - 1)
  let threshold = cast[uint64](input[0])
  if threshold < count or threshold > 1_000_000: return -1
  var maximum = 0'u64
  var total = 0'u64
  for index in 1 ..< int(length):
    let value = cast[uint64](input[index])
    if value == 0 or value > 1_000_000: return -1
    maximum = max(maximum, value)
    total += value
  if threshold == count: return int64(maximum)

  var low = (total - 1) div threshold + 1
  let upperBound = (total - count) div (threshold - count + 1) + 1
  var high = min(maximum, upperBound)
  while low < high:
    let middle = low + ((high - low) shr 1)
    var roundedSum = count
    if count <= 4:
      for index in 1 ..< int(length):
        roundedSum += uint64((uint32(input[index]) - 1) div uint32(middle))
    else:
      let reciprocal = (1_099_511_627_775'u64 div middle) + 1
      for index in 1 ..< int(length):
        roundedSum += ((uint64(input[index]) - 1) * reciprocal) shr 40
    if roundedSum <= threshold: high = middle
    else: low = middle + 1
  int64(low)
