const MaxPoints = 29

type Point32 = object
  x, y: float32

proc koch_snowflake*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "koch_snowflake".} =
  if input == nil or length < 2 or length > 20: return -1
  if input[0] != 0.0 and input[0] != 1.0: return -1
  if input[1] != 2.0 and input[1] != 3.0 and input[1] != 4.0 and input[1] != 5.0 and
      input[1] != 6.0 and input[1] != 7.0 and input[1] != 8.0: return -1
  let steps = int(input[0])
  let pointCount = int(input[1])
  if length != csize_t(2 + 2 * pointCount): return -1
  for i in 0 ..< 2 * pointCount:
    let value = input[i + 2]
    if value != value or value < -1000.0 or value > 1000.0: return -1
  let resultPoints = if steps == 0: pointCount else: 4 * (pointCount - 1) + 1
  let resultCount = 2 * resultPoints
  if output == nil or outputCapacity < csize_t(resultCount): return -2

  var first, second: array[MaxPoints, Point32]
  for i in 0 ..< pointCount:
    first[i] = Point32(x: float32(input[2 + 2*i]), y: float32(input[3 + 2*i]))
  var src = cast[ptr UncheckedArray[Point32]](addr first[0])
  var dst = cast[ptr UncheckedArray[Point32]](addr second[0])
  var srcCount = pointCount
  for step in 0 ..< steps:
    var cursor = 0
    for i in 0 ..< srcCount - 1:
      let start = src[i]
      let finish = src[i + 1]
      let dx = finish.x - start.x
      let dy = finish.y - start.y
      let tx = dx / 3.0'f32
      let ty = dy / 3.0'f32
      let x1 = start.x + tx
      let y1 = start.y + ty
      let rx = 0.49999997'f32 * tx - 0.86602545'f32 * ty
      let ry = 0.86602545'f32 * tx + 0.49999997'f32 * ty
      let tx2 = dx * 2.0'f32 / 3.0'f32
      let ty2 = dy * 2.0'f32 / 3.0'f32
      dst[cursor] = start; inc cursor
      dst[cursor] = Point32(x: x1, y: y1); inc cursor
      dst[cursor] = Point32(x: x1 + rx, y: y1 + ry); inc cursor
      dst[cursor] = Point32(x: start.x + tx2, y: start.y + ty2); inc cursor
    dst[cursor] = src[srcCount - 1]; inc cursor
    srcCount = cursor
    swap(src, dst)
  for i in 0 ..< resultPoints:
    output[2*i] = float64(src[i].x)
    output[2*i+1] = float64(src[i].y)
  int64(resultCount)
