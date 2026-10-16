## Repeated-step polyline length for the source demo curve sin(10*x).
import std/math

const InvalidResult = -1.0e300

proc line_length*(xStart, xEnd, stepsValue: float64): float64
    {.cdecl, exportc: "line_length".} =
  if xStart != xStart or xEnd != xEnd or stepsValue != stepsValue or
      xStart < -10.0 or xStart > 10.0 or xEnd < -10.0 or xEnd > 10.0 or
      xStart > xEnd or stepsValue < 1.0 or stepsValue > 10000.0:
    return InvalidResult
  let steps = int(stepsValue)
  if float64(steps) != stepsValue: return InvalidResult

  var x1 = xStart
  var fx1 = sin(10.0 * xStart)
  var length = 0.0
  for _ in 0 ..< steps:
    let x2 = (xEnd - xStart) / float64(steps) + x1
    let fx2 = sin(10.0 * x2)
    let dx = x2 - x1
    let dy = fx2 - fx1
    length += sqrt(dx * dx + dy * dy)
    x1 = x2
    fx1 = fx2
  length
