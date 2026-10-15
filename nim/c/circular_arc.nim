const InvalidResult = -1.0e300

proc circular_arc*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "circular_arc".} =
  if input.isNil or length != 3: return InvalidResult
  let mode = input[0]
  let radius = input[1]
  let degrees = input[2]
  if (mode != 0 and mode != 1) or radius < -1_000_000 or radius > 1_000_000 or degrees < -360_000 or degrees > 360_000: return InvalidResult
  let angle = float64(degrees) * (PI / 180.0)
  if mode == 0: return float64(radius) * angle
  float64(radius * radius) * angle / 2.0
