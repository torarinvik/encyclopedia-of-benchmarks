import math

const MaxCoordinate = 1_000_000'i64
const InvalidResult = -1.0e300

type I64Input = ptr UncheckedArray[int64]

proc distance_between_two_points*(values: I64Input, length: csize_t): float64
    {.cdecl, exportc: "distance_between_two_points".} =
  if values == nil or length != 4: return InvalidResult
  for index in 0 ..< 4:
    if values[index] < -MaxCoordinate or values[index] > MaxCoordinate: return InvalidResult
  let dx = float64(values[2] - values[0])
  let dy = float64(values[3] - values[1])
  sqrt(dx * dx + dy * dy)
