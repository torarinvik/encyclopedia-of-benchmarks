## Compute a regular dodecahedron's area or volume from its edge length.
import math

proc dodecahedron*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "dodecahedron".} =
  if values == nil or length != 2: return -1.0e300
  let edge = values[0]
  let quantity = values[1]
  if edge < 1 or edge > 1000000 or (quantity != 0 and quantity != 1): return -1.0e300

  let rootFive = sqrt(5.0)
  if quantity == 0:
    let areaFactor = 3.0 * sqrt(25.0 + 10.0 * rootFive)
    return areaFactor * float64(edge * edge)
  let volumeFactor = (15.0 + 7.0 * rootFive) / 4.0
  volumeFactor * float64(edge * edge * edge)
