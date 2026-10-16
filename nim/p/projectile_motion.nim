import std/math

proc projectile_motion*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "projectile_motion".} =
  if values == nil or length != 4: return -1
  for i in 0 ..< 4:
    if values[i] != values[i]: return -1

  let velocity = values[0]
  let angleDegrees = values[1]
  let height = values[2]
  let gravity = values[3]
  if velocity < 0.0 or velocity > 1000.0: return -1
  if angleDegrees < -180.0 or angleDegrees > 180.0: return -1
  if height < 0.0 or height > 1000.0: return -1
  if gravity < 0.1 or gravity > 20.0: return -1

  let angleRadians = angleDegrees / 180.0 * 3.14159265358979323846
  let initialVerticalVelocity = velocity * sin(angleRadians)
  let initialHorizontalVelocity = velocity * cos(angleRadians)
  let totalTimeOfFlight = (initialVerticalVelocity +
    sqrt(initialVerticalVelocity * initialVerticalVelocity + 2.0 * gravity * height)) / gravity
  var maximumHeight = height
  if initialVerticalVelocity > 0.0:
    let heightGained = initialVerticalVelocity * initialVerticalVelocity / (2.0 * gravity)
    maximumHeight = height + heightGained
  let horizontalRange = initialHorizontalVelocity * totalTimeOfFlight

  if output == nil or capacity < 3: return -2
  output[0] = totalTimeOfFlight
  output[1] = horizontalRange
  output[2] = maximumHeight
  3
