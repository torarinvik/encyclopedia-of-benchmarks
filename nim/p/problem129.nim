## Search odd divisors for the first source repunit length exceeding limit.
const MaxLimit = 1_000_000'i64

proc leastDivisibleRepunit(divisor: int64): int64 =
  if divisor mod 5 == 0 or divisor mod 2 == 0: return 0
  var repunit = 1'i64
  var repunitIndex = 1'i64
  while repunit != 0:
    repunit = (10 * repunit + 1) mod divisor
    inc repunitIndex
  repunitIndex

proc problem129*(limit: int64): int64 {.cdecl, exportc: "problem129".} =
  if limit < 1 or limit > MaxLimit: return -1
  var divisor = limit - 1
  if divisor mod 2 == 0: inc divisor
  while leastDivisibleRepunit(divisor) <= limit: divisor += 2
  divisor
