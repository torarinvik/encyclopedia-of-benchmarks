const
  MaxPointCount = 64
  MaxParseableInputLength = 130
  MaxCoordinate = 1_000_000

type Point = object
  x, y: int64

proc pointLess(a, b: Point): bool =
  a.x < b.x or (a.x == b.x and a.y < b.y)

proc crossProduct(origin, first, second: Point): int64 =
  let dx1 = first.x - origin.x
  let dy1 = first.y - origin.y
  let dx2 = second.x - origin.x
  let dy2 = second.y - origin.y
  dx1 * dy2 - dy1 * dx2

proc storeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

## Bounded Andrew monotone-chain convex hull.
proc monotone_chain*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "monotone_chain".} =
  if values == nil or length < 1 or length > csize_t(MaxParseableInputLength): return -1
  let rawCount = values[0]
  if rawCount < 0 or rawCount > MaxPointCount: return -1
  let count = int(rawCount)
  if length != csize_t(1 + 2 * count): return -1

  var points: array[MaxPointCount, Point]
  var scratch: array[MaxPointCount, Point]
  var hull: array[2 * MaxPointCount, Point]
  for index in 0 ..< count:
    let x = values[1 + 2 * index]
    let y = values[2 + 2 * index]
    if x < -MaxCoordinate or x > MaxCoordinate or y < -MaxCoordinate or y > MaxCoordinate: return -1
    points[index] = Point(x: x, y: y)

  var width = 1
  while width < count:
    var start = 0
    while start < count:
      let middle = min(start + width, count)
      let endIndex = min(middle + width, count)
      var left = start
      var right = middle
      var destination = start
      while left < middle and right < endIndex:
        if pointLess(points[right], points[left]):
          scratch[destination] = points[right]
          inc right
        else:
          scratch[destination] = points[left]
          inc left
        inc destination
      while left < middle:
        scratch[destination] = points[left]
        inc left
        inc destination
      while right < endIndex:
        scratch[destination] = points[right]
        inc right
        inc destination
      start += 2 * width
    for index in 0 ..< count:
      points[index] = scratch[index]
    width *= 2

  var uniqueCount = 0
  for index in 0 ..< count:
    if uniqueCount == 0 or points[index].x != points[uniqueCount - 1].x or points[index].y != points[uniqueCount - 1].y:
      points[uniqueCount] = points[index]
      inc uniqueCount

  var hullCount = 0
  if uniqueCount == 1:
    hull[hullCount] = points[0]
    inc hullCount
  elif uniqueCount > 1:
    for index in 0 ..< uniqueCount:
      while hullCount >= 2 and crossProduct(hull[hullCount - 2], hull[hullCount - 1], points[index]) <= 0:
        dec hullCount
      hull[hullCount] = points[index]
      inc hullCount
    let lowerCount = hullCount
    var index = uniqueCount - 1
    while index > 0:
      dec index
      while hullCount > lowerCount and crossProduct(hull[hullCount - 2], hull[hullCount - 1], points[index]) <= 0:
        dec hullCount
      hull[hullCount] = points[index]
      inc hullCount
    dec hullCount

  let byteCount = hullCount * 8
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  for index in 0 ..< hullCount:
    storeI32Le(output, 8 * index, int32(hull[index].x))
    storeI32Le(output, 8 * index + 4, int32(hull[index].y))
  int64(byteCount)
