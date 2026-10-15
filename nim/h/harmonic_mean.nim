const MaxLength = 64
const InvalidResult = -1.0e300

proc harmonic_mean*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "harmonic_mean".} =
  if values == nil or length == 0 or length > csize_t(MaxLength): return InvalidResult
  var reciprocalSum = 0.0
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 1 or value > 1000: return InvalidResult
    reciprocalSum += 1.0 / float64(value)
  return float64(length) / reciprocalSum
