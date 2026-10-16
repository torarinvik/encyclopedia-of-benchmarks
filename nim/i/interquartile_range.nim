## Interquartile range using the source lower/upper-half median rule.
type I64Input = ptr UncheckedArray[int64]

proc medianI64(values: ptr UncheckedArray[int64], count: int): float64 =
  if count mod 2 != 0: return float64(values[count div 2])
  (float64(values[count div 2 - 1]) + float64(values[count div 2])) / 2.0

proc interquartile_range*(values: I64Input, length: csize_t): float64
    {.cdecl, exportc: "interquartile_range".} =
  if values == nil or length < 2 or length > 64: return -1.0e300
  var sorted: array[64, int64]
  for i in 0 ..< int(length):
    if values[i] < -1_000_000 or values[i] > 1_000_000: return -1.0e300
    sorted[i] = values[i]
  for i in 1 ..< int(length):
    let key = sorted[i]
    var j = i
    while j > 0 and sorted[j - 1] > key:
      sorted[j] = sorted[j - 1]
      dec j
    sorted[j] = key
  let half = int(length) div 2
  let upperStart = half + int(length) mod 2
  medianI64(addr sorted[upperStart], half) - medianI64(addr sorted[0], half)
