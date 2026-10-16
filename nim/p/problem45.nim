const MAX_INDEX = 27_693'i64

proc integerSqrt(value: int64): int64 =
  var low = 0'i64
  var high = 200_000'i64
  while high - low > 1:
    let middle = (low + high) div 2
    if middle * middle <= value: low = middle
    else: high = middle
  low

proc isPentagonal(value: int64): bool =
  let discriminant = 24 * value + 1
  let root = integerSqrt(discriminant)
  root * root == discriminant and (root + 1) mod 6 == 0

proc problem45*(start: int64): int64 {.cdecl, exportc: "problem45".} =
  if start < 0 or start > MAX_INDEX: return -1
  var index = start
  while index <= MAX_INDEX:
    let value = index * (2 * index - 1)
    if isPentagonal(value): return value
    inc index
  -1
