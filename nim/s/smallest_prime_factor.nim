const MaxN = 1_000_005

proc smallest_prime_factor*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "smallest_prime_factor".} =
  if input == nil or length != 1: return -1
  let n = input[0]
  if n < 2 or n > MaxN: return -1
  var factor = 2'i64
  while factor <= n div factor:
    if n mod factor == 0: return factor
    inc factor
  n
