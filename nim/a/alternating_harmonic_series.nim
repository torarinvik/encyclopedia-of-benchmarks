## Check that each packed rational matches its canonical alternating term.
const MaxCount = 1000

proc alternating_harmonic_series*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "alternating_harmonic_series".} =
  if length < 1 or length > csize_t(1 + 2 * MaxCount) or values == nil: return -1
  let countValue = values[0]
  if countValue < 0 or countValue > MaxCount: return -1
  let count = int(countValue)
  if length != csize_t(1 + 2 * count): return -1
  if count == 0: return 0

  for index in 0 ..< count:
    let numerator = values[1 + 2 * index]
    let denominator = values[2 + 2 * index]
    if numerator < -1000 or numerator > 1000 or denominator < 1 or denominator > 1000: return -1
    let signedDenominator = if index mod 2 == 0: denominator else: -denominator
    var difference = numerator * int64(index + 1) - signedDenominator
    if difference < 0: difference = -difference
    if difference * 1_000_000_000'i64 > denominator * int64(index + 1): return 0
  1
