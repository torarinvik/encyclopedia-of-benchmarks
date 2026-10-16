import std/math

const InputScale = 1_000_000'i64
const MaxSpeed = 1_000_000_000'i64
const MaxAngle = 360_000_000'i64
const MinGravity = 1_000'i64
const MaxGravity = 100_000_000'i64
const MaxTime = 1_000_000_000'i64
const InvalidResult = -1.0e300
const PiValue = 3.14159265358979323846264338327950288

proc ground_to_ground_projectile_motion*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "ground_to_ground_projectile_motion".} =
  if values == nil or length != 4: return InvalidResult
  let operation = values[0]
  let speedValue = values[1]
  let angleValue = values[2]
  let auxiliaryValue = values[3]
  if operation < 0 or operation > 2 or speedValue < 0 or speedValue > MaxSpeed or
      angleValue < -MaxAngle or angleValue > MaxAngle: return InvalidResult
  if operation == 1:
    if auxiliaryValue < 0 or auxiliaryValue > MaxTime: return InvalidResult
  elif auxiliaryValue < MinGravity or auxiliaryValue > MaxGravity:
    return InvalidResult

  let speed = float64(speedValue) / float64(InputScale)
  let angle = float64(angleValue) / float64(InputScale)
  let radians = angle * (PiValue / 180.0)
  let verticalVelocity = speed * sin(radians)
  if operation == 0:
    let gravity = float64(auxiliaryValue) / float64(InputScale)
    return 2.0 * verticalVelocity / gravity
  if operation == 1:
    let time = float64(auxiliaryValue) / float64(InputScale)
    return (speed * cos(radians)) * time
  let gravity = float64(auxiliaryValue) / float64(InputScale)
  pow(verticalVelocity, 2.0) / (2.0 * gravity)
