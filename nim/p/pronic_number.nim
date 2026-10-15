## Check whether n is the product of two consecutive nonnegative integers.
import math

proc pronic_number*(n: int64): int64 {.cdecl, exportc: "pronic_number".} =
  if n < 0 or n > 2_147_483_647: return -1
  let root = int64(sqrt(float64(n)))
  if root * (root + 1) == n: return 1
  0
