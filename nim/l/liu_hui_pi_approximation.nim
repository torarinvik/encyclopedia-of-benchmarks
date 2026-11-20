import std/math

proc liu_hui_pi_approximation*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "liu_hui_pi_approximation".} =
  if values == nil or length != 1: return -1
  let doublings = values[0]
  if doublings < 0 or doublings > 16: return -1

  var sides = 6'i64
  var side = 1.0
  var apothem = sqrt(0.75)
  var i = 0'i64
  while i < doublings:
    let halfSide = side / 2.0
    let height = 1.0 - apothem
    side = sqrt(halfSide * halfSide + height * height)
    sides *= 2
    let nextHalfSide = side / 2.0
    apothem = sqrt(1.0 - nextHalfSide * nextHalfSide)
    i += 1

  let area = float64(sides) * side * apothem / 2.0
  return int64(area * 1_000_000.0 + 0.5)
