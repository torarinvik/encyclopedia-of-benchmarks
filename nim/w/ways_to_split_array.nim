## Count positions where the prefix sum is at least the remaining suffix sum.
const MaxLength = 100_000
const MaxValue = 100_000'i64

proc ways_to_split_array*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ways_to_split_array".} =
  if values == nil or length < 2 or length > MaxLength: return -1
  let n = int(length)
  var total = 0'u64
  var largestBiasedValue = 0'u64
  for index in 0 ..< n:
    let value = cast[uint64](values[index])
    largestBiasedValue = max(largestBiasedValue, value + uint64(MaxValue))
    total += value
  if largestBiasedValue > 2 * uint64(MaxValue): return -1
  let signedTotal = cast[int64](total)
  let threshold = signedTotal div 2 + int64(signedTotal > 0 and signedTotal mod 2 != 0)
  var prefix = 0'u64
  var ways = 0'i64
  for index in 0 ..< n - 1:
    prefix += cast[uint64](values[index])
    if cast[int64](prefix) >= threshold: inc ways
  ways
