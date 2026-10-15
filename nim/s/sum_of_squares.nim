## Minimum number of perfect squares summing to value, using Lagrange's theorem.
proc sum_of_squares*(value: int64): int64 {.cdecl, exportc: "sum_of_squares".} =
  if value < 0 or value > 2_147_483_647: return -1
  if value == 0: return 0

  var low = 1'i64
  var high = value
  while high - low > 1:
    let middle = low + (high - low) div 2
    if middle <= value div middle: low = middle
    else: high = middle
  let root = low
  if root * root == value: return 1

  var second = root
  for first in 1'i64 .. root:
    let remainder = value - first * first
    while second * second > remainder: dec second
    if second * second == remainder: return 2

  var reduced = value
  while reduced mod 4 == 0: reduced = reduced div 4
  if reduced mod 8 == 7: return 4
  3
