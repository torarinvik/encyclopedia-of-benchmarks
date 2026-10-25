## Clean-room bounded GICOV recurrence; complete applicable notice is in package LICENSE.txt.
const EllipseCount = 7
const MaxPoints = 16
const InvalidResult = -1.0e300

proc decode(raw: int64): float32 = float32(raw) / 1_000_000.0'f32

proc rodinia_leukocyte_gicov*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "rodinia_leukocyte_gicov".} =
  if input.isNil or length < csize_t(1): return InvalidResult
  if input[0] < 2 or input[0] > MaxPoints: return InvalidResult
  let points = int(input[0])
  if length != csize_t(1 + EllipseCount * points): return InvalidResult
  for i in 1 ..< int(length):
    if input[i] < -1_000_000 or input[i] > 1_000_000: return InvalidResult

  var maximum = 0.0'f32
  for ellipse in 0 ..< EllipseCount:
    var sum = 0.0'f32
    var mean = 0.0'f32
    var m2 = 0.0'f32
    let base = 1 + ellipse * points
    for n in 0 ..< points:
      let p = decode(input[base + n])
      sum = sum + p
      let delta = p - mean
      mean = mean + delta / float32(n + 1)
      m2 = m2 + delta * (p - mean)
    mean = sum / float32(points)
    let variance = m2 / float32(points - 1)
    if not (variance > 0.0'f32): return InvalidResult
    let score = (mean * mean) / variance
    if score > maximum: maximum = score
  float64(maximum)
