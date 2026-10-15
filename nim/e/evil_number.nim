## Return 1 when a nonnegative integer has an even popcount.
proc evil_number*(value: int64): int64 {.cdecl, exportc: "evil_number".} =
  if value < 0: return -1
  var remaining = value
  var count = 0
  while remaining > 0:
    count += int(remaining and 1)
    remaining = remaining shr 1
  if count mod 2 == 0: 1 else: 0
