proc distinctPrimeFactorCount(valueInput: int64): int64 =
  var value = valueInput
  var count: int64 = 0
  var divisor: int64 = 2
  while divisor * divisor <= value:
    if value mod divisor == 0:
      inc count
      while value mod divisor == 0:
        value = value div divisor
    inc divisor
  if value > 1:
    inc count
  count

proc problem47*(n: int64): int64 {.cdecl, exportc: "problem47".} =
  if n < 1 or n > 4: return -1
  var value: int64 = 2
  var runLength: int64 = 0
  while true:
    if distinctPrimeFactorCount(value) == n:
      inc runLength
    else:
      runLength = 0
    if runLength == n: return value - n + 1
    inc value
