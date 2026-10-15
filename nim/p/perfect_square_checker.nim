## Check whether a signed 32-bit integer is a perfect square.
proc perfect_square_checker*(n: int64): int64 {.cdecl, exportc: "perfect_square_checker".} =
  if n < -2_147_483_648'i64 or n > 2_147_483_647'i64: return -1
  if n < 0: return 0

  var low = 0'i64
  var high = 46_340'i64
  while low <= high:
    let mid = low + (high - low) div 2
    let square = mid * mid
    if square == n: return 1
    if square < n: low = mid + 1
    else: high = mid - 1
  return 0
