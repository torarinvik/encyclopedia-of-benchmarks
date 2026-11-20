import std/math

const MaxVertices = 16
const MaxInput = 37
const MaxCoordinate = 32'i64
const InvalidResult = -1.0e300
type I64Input = ptr UncheckedArray[int64]

proc circle_polygon_intersection_area*(values: I64Input, length: csize_t): float64
    {.cdecl, exportc: "circle_polygon_intersection_area".} =
  if values.isNil or length < 10 or length > csize_t(MaxInput): return InvalidResult
  let nValue = values[0]
  let cx = values[1]
  let cy = values[2]
  let radiusValue = values[3]
  if nValue < 3 or nValue > MaxVertices: return InvalidResult
  if length != csize_t(4 + 2 * nValue): return InvalidResult
  if cx < -MaxCoordinate or cx > MaxCoordinate or cy < -MaxCoordinate or cy > MaxCoordinate or
      radiusValue < 1 or radiusValue > MaxCoordinate: return InvalidResult
  let n = int(nValue)
  for i in 0 ..< n:
    let x = values[4 + 2 * i]
    let y = values[5 + 2 * i]
    if x < -MaxCoordinate or x > MaxCoordinate or y < -MaxCoordinate or y > MaxCoordinate:
      return InvalidResult
  for i in 0 ..< n:
    let next = (i + 1) mod n
    let x = values[4 + 2 * i]
    let y = values[5 + 2 * i]
    let dx = values[4 + 2 * next] - x
    let dy = values[5 + 2 * next] - y
    for j in 0 ..< n:
      if j == i or j == next: continue
      let side = dx * (values[5 + 2 * j] - y) - dy * (values[4 + 2 * j] - x)
      if side <= 0: return InvalidResult
    if dx * (cy - y) - dy * (cx - x) <= 0: return InvalidResult

  let radius = float64(radiusValue)
  let radiusSquared = radius * radius
  var doubledArea = 0.0
  for i in 0 ..< n:
    let next = (i + 1) mod n
    let px = float64(values[4 + 2 * i] - cx)
    let py = float64(values[5 + 2 * i] - cy)
    let qx = float64(values[4 + 2 * next] - cx)
    let qy = float64(values[5 + 2 * next] - cy)
    let edgeX = qx - px
    let edgeY = qy - py
    let edgeSquared = edgeX * edgeX + edgeY * edgeY
    let projection = px * edgeX + py * edgeY
    let constant = px * px + py * py - radiusSquared
    let discriminant = projection * projection - edgeSquared * constant
    let fullAngle = arctan2(px * qy - py * qx, px * qx + py * qy)
    if discriminant <= 0.0:
      doubledArea += radiusSquared * fullAngle
      continue
    let root = sqrt(discriminant)
    let first = (-projection - root) / edgeSquared
    let second = (-projection + root) / edgeSquared
    if second < 0.0 or first > 1.0:
      doubledArea += radiusSquared * fullAngle
      continue
    let start = max(0.0, first)
    let stop = min(1.0, second)
    let ux = px + start * edgeX
    let uy = py + start * edgeY
    let vx = px + stop * edgeX
    let vy = py + stop * edgeY
    let firstAngle = arctan2(px * uy - py * ux, px * ux + py * uy)
    let lastAngle = arctan2(vx * qy - vy * qx, vx * qx + vy * qy)
    doubledArea += radiusSquared * (firstAngle + lastAngle) + ux * vy - uy * vx
  0.5 * doubledArea
