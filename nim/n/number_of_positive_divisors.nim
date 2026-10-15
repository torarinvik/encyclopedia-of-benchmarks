## Count positive divisors of the absolute value of one signed integer.
proc number_of_positive_divisors*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_positive_divisors".} =
  if values == nil or length != 1 or values[0] < -1_000_000_000 or values[0] > 1_000_000_000:
    return -1
  var remaining = if values[0] < 0: -values[0] else: values[0]
  var count = 1'i64
  var factor = 2'i64
  while factor * factor <= remaining:
    var exponent = 0'i64
    while remaining mod factor == 0:
      remaining = remaining div factor
      inc exponent
    count *= exponent + 1
    inc factor
  if remaining > 1: count *= 2
  count
