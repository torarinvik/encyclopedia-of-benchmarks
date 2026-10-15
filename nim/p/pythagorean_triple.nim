## Check three signed integers with Java-compatible int-safe bounds.
proc pythagorean_triple*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "pythagorean_triple".} =
  if length != 3 or values == nil: return -1
  var a = values[0]
  var b = values[1]
  var c = values[2]
  if a < -32768 or a > 32767 or b < -32768 or b > 32767 or c < -32768 or c > 32767: return -1
  if a <= 0 or b <= 0 or c <= 0: return 0
  if a > b: swap(a, b)
  if b > c: swap(b, c)
  if a > b: swap(a, b)
  if a * a + b * b == c * c: 1 else: 0
