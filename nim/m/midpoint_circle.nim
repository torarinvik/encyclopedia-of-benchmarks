proc plottedPointCount(radius: int64): csize_t =
  if radius == 0:
    return 1
  var x = radius
  var y = 0'i64
  var decision = 1'i64 - radius
  result = 8
  while x > y:
    inc y
    if decision <= 0:
      decision += 2 * y + 1
    else:
      dec x
      decision += 2 * y - 2 * x + 1
    result += 8

proc writePoint(output: ptr UncheckedArray[uint8], pointIndex: csize_t,
    centerX, centerY, x, y: int64) =
  let offsets = [(x, y), (-x, y), (x, -y), (-x, -y),
    (y, x), (-y, x), (y, -x), (-y, -x)]
  for point, offset in offsets:
    let pointX = cast[uint32](int32(centerX + offset[0]))
    let pointY = cast[uint32](int32(centerY + offset[1]))
    let byteIndex = int((pointIndex + csize_t(point)) * 8)
    for byte in 0 ..< 4:
      output[byteIndex + byte] = uint8((pointX shr (8 * byte)) and 0xFF'u32)
      output[byteIndex + 4 + byte] = uint8((pointY shr (8 * byte)) and 0xFF'u32)

proc midpoint_circle*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "midpoint_circle".} =
  if length != 3 or values == nil: return -1
  let centerX = values[0]
  let centerY = values[1]
  let radius = values[2]
  if centerX < -10_000 or centerX > 10_000 or centerY < -10_000 or
      centerY > 10_000 or radius < 0 or radius > 1_000:
    return -1

  let count = plottedPointCount(radius)
  if output == nil or outputCapacity < count * 8: return -2
  if radius == 0:
    let pointX = cast[uint32](int32(centerX))
    let pointY = cast[uint32](int32(centerY))
    for byte in 0 ..< 4:
      output[byte] = uint8((pointX shr (8 * byte)) and 0xFF'u32)
      output[4 + byte] = uint8((pointY shr (8 * byte)) and 0xFF'u32)
    return 1

  var pointIndex = 0.csize_t
  var x = radius
  var y = 0'i64
  var decision = 1'i64 - radius
  while true:
    writePoint(output, pointIndex, centerX, centerY, x, y)
    pointIndex += 8
    if x <= y: break
    inc y
    if decision <= 0:
      decision += 2 * y + 1
    else:
      dec x
      decision += 2 * y - 2 * x + 1
  int64(count)
