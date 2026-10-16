## Find the first odd prime index whose source remainder exceeds the limit.
const MaxLimit = 10_000_000_000'i64
const PrimeLimit = 300_000

proc problem123*(limit: int64): int64 {.cdecl, exportc: "problem123".} =
  if limit > MaxLimit: return -1
  var composite: array[PrimeLimit + 1, bool]
  var factor = 2
  while factor * factor <= PrimeLimit:
    if not composite[factor]:
      var multiple = factor * factor
      while multiple <= PrimeLimit:
        composite[multiple] = true
        multiple += factor
    inc factor
  var n = 1'i64
  var skipNext = false
  for candidate in 2 .. PrimeLimit:
    if composite[candidate]: continue
    if skipNext:
      skipNext = false
      continue
    if 2'i64 * candidate.int64 * n > limit: return n
    skipNext = true
    n += 2
  -1
