import std/math

const MaxValue = 1_000_000.0
const InvalidResult = -1.0

proc arithmetic_geometric_mean*(first, second: float64): float64 {.cdecl, exportc: "arithmetic_geometric_mean".} =
  if first != first or second != second or first < 0.0 or second < 0.0 or
      first > MaxValue or second > MaxValue: return InvalidResult
  if first == second: return first

  var arithmetic = first
  var geometric = second
  var previous: float64
  while true:
    previous = arithmetic
    let nextArithmetic = (arithmetic + geometric) / 2.0
    let nextGeometric = sqrt(arithmetic * geometric)
    arithmetic = nextArithmetic
    geometric = nextGeometric
    if arithmetic == previous: break
  arithmetic
