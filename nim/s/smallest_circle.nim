import math

type Point = tuple[x, y: int64]

proc contains(points: array[12, Point], count: int, centerX, centerY, radius: float64): bool =
  let radiusSquared = radius * radius
  for index in 0 ..< count:
    let dx = float64(points[index].x) - centerX
    let dy = float64(points[index].y) - centerY
    if dx * dx + dy * dy > radiusSquared + 1.0e-12: return false
  true

proc consider(points: array[12, Point], count: int, centerX, centerY, radius: float64,
    bestX, bestY, bestRadius: var float64, found: var bool) =
  if contains(points, count, centerX, centerY, radius) and
      (not found or radius <= bestRadius):
    bestX = centerX
    bestY = centerY
    bestRadius = radius
    found = true

proc writeCircle(output: ptr UncheckedArray[uint8], capacity: csize_t,
    centerX, centerY, radius: float64): int64 =
  if output == nil or capacity < 24: return -2
  let values = [centerX, centerY, radius]
  for valueIndex in 0 ..< 3:
    let bits = cast[uint64](values[valueIndex])
    for byteIndex in 0 ..< 8:
      output[valueIndex * 8 + byteIndex] = uint8((bits shr (byteIndex * 8)) and 0xFF'u64)
  1

proc smallest_circle*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "smallest_circle".} =
  if input == nil or length < 2 or length > 24 or length mod 2 != 0: return -1
  let count = int(length div 2)
  if count < 1 or count > 12: return -1
  var points: array[12, Point]
  for index in 0 ..< count:
    let x = input[2 * index]
    let y = input[2 * index + 1]
    if x < -100 or x > 100 or y < -100 or y > 100: return -1
    points[index] = (x, y)
  if count == 1:
    return writeCircle(output, outputCapacity, float64(points[0].x), float64(points[0].y), 0.0)

  var bestX = 0.0
  var bestY = 0.0
  var bestRadius = 0.0
  var found = false
  for i in 0 ..< count:
    for j in (i + 1) ..< count:
      for k in (j + 1) ..< count:
        let a = points[i]
        let b = points[j]
        let c = points[k]
        let ax = float64(a.x)
        let ay = float64(a.y)
        let bx = float64(b.x)
        let by = float64(b.y)
        let cx = float64(c.x)
        let cy = float64(c.y)
        let denominator = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
        if denominator == 0.0: continue
        let aSquared = ax * ax + ay * ay
        let bSquared = bx * bx + by * by
        let cSquared = cx * cx + cy * cy
        let centerX = (aSquared * (by - cy) + bSquared * (cy - ay) + cSquared * (ay - by)) / denominator
        let centerY = (aSquared * (cx - bx) + bSquared * (ax - cx) + cSquared * (bx - ax)) / denominator
        let dx = ax - centerX
        let dy = ay - centerY
        consider(points, count, centerX, centerY, sqrt(dx * dx + dy * dy), bestX, bestY, bestRadius, found)
  for i in 0 ..< count:
    for j in (i + 1) ..< count:
      let centerX = (float64(points[i].x) + float64(points[j].x)) / 2.0
      let centerY = (float64(points[i].y) + float64(points[j].y)) / 2.0
      let dx = float64(points[i].x) - centerX
      let dy = float64(points[i].y) - centerY
      consider(points, count, centerX, centerY, sqrt(dx * dx + dy * dy), bestX, bestY, bestRadius, found)
  if not found: return -1
  writeCircle(output, outputCapacity, bestX, bestY, bestRadius)
