import algorithm, math

const MaxPoints = 1024
const MaxCoordinate = 1_000_000_000'i64
const InvalidResult = -1.0e300

type
  Point = object
    x, y: int64

proc cross(origin, a, b: Point): int64 =
  (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x)

proc distanceSquared(a, b: Point): int64 =
  let dx = a.x - b.x
  let dy = a.y - b.y
  dx * dx + dy * dy

proc rotating_calipers*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "rotating_calipers".} =
  if values == nil or length < 5 or length > csize_t(2 * MaxPoints + 1) or length mod 2 == 0:
    return InvalidResult
  let countValue = values[0]
  if countValue < 2 or countValue > int64(MaxPoints) or length != csize_t(1 + 2 * countValue):
    return InvalidResult
  let count = int(countValue)
  var points = newSeqOfCap[Point](count)
  for index in 0 ..< count:
    let x = values[1 + 2 * index]
    let y = values[2 + 2 * index]
    if x < -MaxCoordinate or x > MaxCoordinate or y < -MaxCoordinate or y > MaxCoordinate:
      return InvalidResult
    points.add(Point(x: x, y: y))
  points.sort(proc(a, b: Point): int =
    result = cmp(a.x, b.x)
    if result == 0: result = cmp(a.y, b.y))
  var unique: seq[Point] = @[]
  for point in points:
    if unique.len == 0 or unique[^1].x != point.x or unique[^1].y != point.y:
      unique.add(point)
  if unique.len == 1: return 0.0

  var lower: seq[Point] = @[]
  for point in unique:
    while lower.len >= 2 and cross(lower[^2], lower[^1], point) <= 0: lower.setLen(lower.len - 1)
    lower.add(point)
  var upper: seq[Point] = @[]
  for index in countdown(unique.len - 1, 0):
    let point = unique[index]
    while upper.len >= 2 and cross(upper[^2], upper[^1], point) <= 0: upper.setLen(upper.len - 1)
    upper.add(point)
  lower.setLen(lower.len - 1)
  upper.setLen(upper.len - 1)
  lower.add(upper)
  let hull = lower
  if hull.len == 2: return sqrt(float64(distanceSquared(hull[0], hull[1])))

  let hullSize = hull.len
  var antipodal = 1
  var advances = 0
  while advances < hullSize and
      cross(hull[0], hull[1], hull[(antipodal + 1) mod hullSize]) >
      cross(hull[0], hull[1], hull[antipodal]):
    antipodal = (antipodal + 1) mod hullSize
    inc advances
  var maximumSquared: int64 = 0
  for current in 0 ..< hullSize:
    let next = (current + 1) mod hullSize
    advances = 0
    while advances < hullSize and
        cross(hull[current], hull[next], hull[(antipodal + 1) mod hullSize]) >
        cross(hull[current], hull[next], hull[antipodal]):
      antipodal = (antipodal + 1) mod hullSize
      inc advances
    let after = (antipodal + 1) mod hullSize
    maximumSquared = max(maximumSquared, distanceSquared(hull[current], hull[antipodal]))
    maximumSquared = max(maximumSquared, distanceSquared(hull[next], hull[antipodal]))
    maximumSquared = max(maximumSquared, distanceSquared(hull[current], hull[after]))
    maximumSquared = max(maximumSquared, distanceSquared(hull[next], hull[after]))
  sqrt(float64(maximumSquared))
