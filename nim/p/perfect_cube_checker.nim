## Check whether a signed 32-bit integer is a perfect cube.
proc perfect_cube_checker*(n: int64): int64 {.cdecl, exportc: "perfect_cube_checker".} =
  if n < -2_147_483_648'i64 or n > 2_147_483_647'i64: return -1

  let magnitude = (if n < 0: -n else: n)
  var low = 0'i64
  var high = 1290'i64
  while low <= high:
    let mid = low + (high - low) div 2
    let cube = mid * mid * mid
    if cube == magnitude: return 1
    if cube < magnitude: low = mid + 1
    else: high = mid - 1
  return 0
