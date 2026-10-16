## Encode the source divisor list in a lossless positive signed-i64 bit mask.
proc divisors*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "divisors".} =
  if values == nil or length != 1: return -1
  let n = values[0]
  if n < 1 or n > 62: return -1
  var mask = 0'u64
  var divisor = 1'i64
  while divisor <= n:
    if n mod divisor == 0:
      mask = mask or (1'u64 shl int(divisor))
    inc divisor
  int64(mask)
