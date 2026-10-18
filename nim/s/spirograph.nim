import std/math

const MaxInputLength = 5
const MaxPoints = 32

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc spirograph*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "spirograph".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if inputLength != 4: return -1
  if not exactInteger(input[0], 1, MaxPoints): return -1
  let points = int(input[0])
  let markerRatio = input[1]
  let innerRatio = input[2]
  let rotations = input[3]
  if classify(markerRatio) in {fcNan, fcInf, fcNegInf} or markerRatio < 0.0 or markerRatio > 1.0: return -1
  if classify(innerRatio) in {fcNan, fcInf, fcNegInf} or innerRatio < 0.25 or innerRatio > 0.75: return -1
  if classify(rotations) in {fcNan, fcInf, fcNegInf} or rotations < 0.0 or rotations > 10.0: return -1

  let delta = rotations * 2.0 * PI / float64(points)
  let k1 = 1.0 - innerRatio
  var staged: array[64, float64]
  for index in 0 ..< points:
    let t = float64(index) * delta
    let innerAngle = k1 * t / innerRatio
    let x = k1 * cos(t) + markerRatio * innerRatio * cos(innerAngle)
    let y = k1 * sin(t) - markerRatio * innerRatio * sin(innerAngle)
    if classify(x) in {fcNan, fcInf, fcNegInf} or classify(y) in {fcNan, fcInf, fcNegInf}: return -1
    staged[2 * index] = x
    staged[2 * index + 1] = y

  let outputLength = 2 * points
  if output == nil or capacity < csize_t(outputLength): return -2
  for index in 0 ..< outputLength: output[index] = staged[index]
  int64(outputLength)
