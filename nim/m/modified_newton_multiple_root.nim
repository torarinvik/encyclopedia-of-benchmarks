import std/math

proc modified_newton_multiple_root*(initialX, iterationCount: float64): float64
    {.cdecl, exportc: "modified_newton_multiple_root".} =
  if initialX != initialX or iterationCount != iterationCount or
      initialX < 1.0 or initialX > 2.0 or iterationCount < 0.0 or
      iterationCount > 8.0 or floor(iterationCount) != iterationCount:
    return -1.0

  var x = initialX
  let count = int(iterationCount)
  for i in 0 ..< count:
    if x == 1.0:
      break
    let offset = x - 1.0
    let value = offset * offset * (x + 2.0)
    let derivative = 3.0 * offset * (x + 1.0)
    if derivative == 0.0 or derivative != derivative:
      return -1.0
    x = x - 2.0 * (value / derivative)
    if x != x or x < 1.0 or x > 2.0:
      return -1.0
  x
