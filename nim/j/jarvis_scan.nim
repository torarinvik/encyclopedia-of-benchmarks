## Return an integer Jarvis-scan hull in counter-clockwise order.
const
  MaxPoints = 64
  MinCoordinate = -10_000'i64
  MaxCoordinate = 10_000'i64

proc orientation(ax, ay, bx, by, cx, cy: int64): int64 =
  (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255)

proc jarvis_scan*(input: ptr UncheckedArray[int64], length: csize_t,
                  output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "jarvis_scan".} =
  if input == nil or length < 1: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxPoints: return -1
  let count = int(countValue)
  if int(length) != 1 + 2 * count: return -1

  var x: array[MaxPoints, int64]
  var y: array[MaxPoints, int64]
  for point in 0 ..< count:
    x[point] = input[1 + 2 * point]
    y[point] = input[2 + 2 * point]
    if x[point] < MinCoordinate or x[point] > MaxCoordinate or
        y[point] < MinCoordinate or y[point] > MaxCoordinate: return -1
  if count <= 2: return 0

  for first in 0 ..< count:
    for second in first + 1 ..< count:
      if x[first] == x[second] and y[first] == y[second]: return -1
  for first in 0 ..< (count - 2):
    for second in (first + 1) ..< (count - 1):
      for third in second + 1 ..< count:
        if orientation(x[first], y[first], x[second], y[second], x[third], y[third]) == 0: return -1

  var start = 0
  for point in 1 ..< count:
    if x[point] < x[start] or (x[point] == x[start] and y[point] < y[start]): start = point
  var hull: array[MaxPoints, int]
  var hullCount = 0
  var current = start
  while true:
    if hullCount == count: return -1
    hull[hullCount] = current
    inc hullCount
    var candidate = (current + 1) mod count
    for point in 0 ..< count:
      if orientation(x[current], y[current], x[point], y[point], x[candidate], y[candidate]) > 0:
        candidate = point
    if candidate == start: break
    current = candidate

  let bytes = hullCount * 16
  if output == nil or int(capacity) < bytes: return -2
  for index in 0 ..< hullCount:
    putI64(output, index * 16, x[hull[index]])
    putI64(output, index * 16 + 8, y[hull[index]])
  int64(bytes)
