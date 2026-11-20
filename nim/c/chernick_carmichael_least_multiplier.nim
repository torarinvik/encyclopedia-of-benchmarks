const MaxMultiplier = 950560'i64

proc ccmIsPrime(value: int64): bool =
  if value < 2:
    return false
  if value mod 2 == 0:
    return value == 2
  var divisor = 3'i64
  while divisor <= value div divisor:
    if value mod divisor == 0:
      return false
    inc divisor, 2
  true

proc ccmFactorsArePrime(n, multiplier: int64): bool =
  if not ccmIsPrime(6 * multiplier + 1):
    return false
  if not ccmIsPrime(12 * multiplier + 1):
    return false

  var powerOfTwo = 2'i64
  var factorIndex = 1'i64
  while factorIndex <= n - 2:
    if not ccmIsPrime(9 * multiplier * powerOfTwo + 1):
      return false
    powerOfTwo *= 2
    inc factorIndex
  true

proc chernick_carmichael_least_multiplier*(input: ptr UncheckedArray[int64],
                                          length: csize_t): int64
    {.cdecl, exportc: "chernick_carmichael_least_multiplier".} =
  if input.isNil or length != csize_t(1):
    return -1
  let n = input[0]
  if n < 3 or n > 9:
    return -1

  var step = 1'i64
  if n > 4:
    step = 1'i64 shl int(n - 4)
  if n > 5:
    step *= 5

  var multiplier = step
  while multiplier <= MaxMultiplier:
    if ccmFactorsArePrime(n, multiplier):
      return multiplier
    multiplier += step
  -1
