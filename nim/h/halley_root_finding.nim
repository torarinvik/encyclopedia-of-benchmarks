import std/math

proc halley_root_finding*(initialX, iterationCount: float64): float64
    {.cdecl, exportc: "halley_root_finding".} =
  if initialX != initialX or iterationCount != iterationCount or
      initialX < 0.5 or initialX > 2.0 or iterationCount < 0.0 or
      iterationCount > 8.0 or floor(iterationCount) != iterationCount:
    return -1.0

  var x = initialX
  let count = int(iterationCount)
  for i in 0 ..< count:
    let value = x * x * x - 2.0
    let first = 3.0 * x * x
    let second = 6.0 * x
    let denominator = 2.0 * first * first - value * second
    if denominator == 0.0 or denominator != denominator:
      return -1.0
    x = x - (2.0 * value * first) / denominator
    if x != x or x < 0.5 or x > 2.0:
      return -1.0
  x
