## Newton-Raphson square root under the pinned integer input contract.
import std/math

const InvalidResult = -1.0e300
const MaxInput = 2147483647.0

proc squareRootWithNewtonRaphsonMethod*(input: float64): float64
    {.cdecl, exportc: "square_root_with_newton_raphson_method".} =
  if input != input or input < 1.0 or input > MaxInput or floor(input) != input:
    return InvalidResult
  var guess = input
  var root = 0.5 * (guess + input / guess)
  while abs(root - guess) > 1e-7:
    guess = root
    root = 0.5 * (guess + input / guess)
  root
