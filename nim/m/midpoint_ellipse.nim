proc ellipsePointCount(a, b: int64): csize_t =
  if a == 0: return csize_t(2 * b + 1)
  if b == 0: return csize_t(2 * a + 1)

  let aa = a * a
  let bb = b * b
  var x = 0'i64
  var y = b
  var dx = 2 * bb * x
  var dy = 2 * aa * y
  var d1 = float64(bb) - float64(aa * b) + 0.25 * float64(aa)
  result = 0
  while dx < dy:
    result += 4
    if d1 < 0.0:
      inc x
      dx += 2 * bb
      d1 += float64(dx + bb)
    else:
      inc x
      dec y
      dx += 2 * bb
      dy -= 2 * aa
      d1 += float64(dx - dy + bb)

  var d2 = float64(bb) * (float64(x) + 0.5) * (float64(x) + 0.5) +
    float64(aa) * float64(y - 1) * float64(y - 1) - float64(aa * bb)
  while y >= 0:
    result += 4
    if d2 > 0.0:
      dec y
      dy -= 2 * aa
      d2 += float64(aa - dy)
    else:
      dec y
      inc x
      dx += 2 * bb
      dy -= 2 * aa
      d2 += float64(dx - dy + aa)

proc writePoint(output: ptr UncheckedArray[uint8], pointIndex: csize_t,
    x, y: int64) =
  let xBits = cast[uint32](int32(x))
  let yBits = cast[uint32](int32(y))
  let byteIndex = int(pointIndex * 8)
  for byte in 0 ..< 4:
    output[byteIndex + byte] = uint8((xBits shr (8 * byte)) and 0xFF'u32)
    output[byteIndex + 4 + byte] = uint8((yBits shr (8 * byte)) and 0xFF'u32)

proc emitQuadrant(output: ptr UncheckedArray[uint8], pointIndex: csize_t,
    centerX, centerY, x, y: int64) =
  writePoint(output, pointIndex, centerX + x, centerY + y)
  writePoint(output, pointIndex + 1, centerX - x, centerY + y)
  writePoint(output, pointIndex + 2, centerX + x, centerY - y)
  writePoint(output, pointIndex + 3, centerX - x, centerY - y)

proc midpoint_ellipse*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "midpoint_ellipse".} =
  if length != 4 or values == nil: return -1
  let centerX = values[0]
  let centerY = values[1]
  let a = values[2]
  let b = values[3]
  if centerX < -10_000 or centerX > 10_000 or centerY < -10_000 or
      centerY > 10_000 or a < 0 or a > 100 or b < 0 or b > 100:
    return -1

  let count = if a == 0 and b == 0: 1.csize_t else: ellipsePointCount(a, b)
  if output == nil or outputCapacity < count * 8: return -2
  if a == 0 and b == 0:
    writePoint(output, 0, centerX, centerY)
    return 1
  if a == 0:
    for offset in 0 .. (2 * b):
      writePoint(output, csize_t(offset), centerX, centerY - b + offset)
    return int64(count)
  if b == 0:
    for offset in 0 .. (2 * a):
      writePoint(output, csize_t(offset), centerX - a + offset, centerY)
    return int64(count)

  let aa = a * a
  let bb = b * b
  var x = 0'i64
  var y = b
  var dx = 2 * bb * x
  var dy = 2 * aa * y
  var d1 = float64(bb) - float64(aa * b) + 0.25 * float64(aa)
  var pointIndex = 0.csize_t
  while dx < dy:
    emitQuadrant(output, pointIndex, centerX, centerY, x, y)
    pointIndex += 4
    if d1 < 0.0:
      inc x
      dx += 2 * bb
      d1 += float64(dx + bb)
    else:
      inc x
      dec y
      dx += 2 * bb
      dy -= 2 * aa
      d1 += float64(dx - dy + bb)

  var d2 = float64(bb) * (float64(x) + 0.5) * (float64(x) + 0.5) +
    float64(aa) * float64(y - 1) * float64(y - 1) - float64(aa * bb)
  while y >= 0:
    emitQuadrant(output, pointIndex, centerX, centerY, x, y)
    pointIndex += 4
    if d2 > 0.0:
      dec y
      dy -= 2 * aa
      d2 += float64(aa - dy)
    else:
      dec y
      inc x
      dx += 2 * bb
      dy -= 2 * aa
      d2 += float64(dx - dy + aa)
  int64(count)
