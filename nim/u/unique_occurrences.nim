## Check whether every present value has a distinct occurrence count.
proc unique_occurrences*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "unique_occurrences".} =
  if length == 0: return 1
  if length > 1000 or values.isNil: return -1
  let n = int(length)
  let first = cast[uint64](values[0])
  if n == 1: return (if first + 1000 <= 2000: 1 else: -1)
  var largestBiased, differentBits: uint64
  for index in 0 ..< n:
    let value = cast[uint64](values[index])
    differentBits = differentBits or (value xor first)
    largestBiased = max(largestBiased, value + 1000)
  if largestBiased > 2000: return -1
  if differentBits == 0: return 1

  var counts: array[2001, uint16]
  var touched: array[44, uint16]
  var distinctCount = 0
  for index in 0 ..< n:
    let slot = int(values[index] + 1000)
    if counts[slot] == 0:
      let nextDistinct = distinctCount + 1
      if nextDistinct * (nextDistinct + 1) > 2 * n: return 0
      touched[distinctCount] = uint16(slot)
      distinctCount = nextDistinct
    inc counts[slot]

  var seen: array[16, uint64]
  for index in 0 ..< distinctCount:
    let frequency = int(counts[int(touched[index])])
    let word = frequency shr 6
    let bit = 1'u64 shl (frequency and 63)
    if (seen[word] and bit) != 0: return 0
    seen[word] = seen[word] or bit
  1
