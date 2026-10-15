## Return radius for component 0 and the atan2 angle for component 1.
import std/math

proc cartesian_to_polar*(x, y, component: float64): float64
    {.cdecl, exportc: "cartesian_to_polar".} =
  if x != x or y != y or (component != 0.0 and component != 1.0): return -1.0e300
  if x < -1_000_000.0 or x > 1_000_000.0 or y < -1_000_000.0 or y > 1_000_000.0:
    return -1.0e300
  if component == 0.0: return sqrt(x * x + y * y)
  if x == 0.0 and y == 0.0: return 0.0
  arctan2(y, x)
