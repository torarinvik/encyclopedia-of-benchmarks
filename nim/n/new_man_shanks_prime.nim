const MaxIndex = 25'i64
const Int32MinValue = -2_147_483_648'i64
const Int32MaxValue = 2_147_483_647'i64

## Compare the source recurrence term a[n] with expected; this is not primality testing.
proc new_man_shanks_prime*(n, expected: int64): int64 {.cdecl, exportc: "new_man_shanks_prime".} =
  if n < 1 or n > MaxIndex or expected < Int32MinValue or expected > Int32MaxValue:
    return -1
  var previousPrevious = 1'i32
  var previous = 1'i32
  if n == 1: return if expected == int64(previous): 1 else: 0
  for index in 2'i64..n:
    let current = 2'i32 * previous + previousPrevious
    previousPrevious = previous
    previous = current
  if expected == int64(previous): 1 else: 0
