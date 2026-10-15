proc writePoint(output: ptr UncheckedArray[uint8], pointIndex: int64,
    x, y: int64) =
  let pointX = cast[uint32](int32(x))
  let pointY = cast[uint32](int32(y))
  let byteIndex = int(pointIndex * 8)
  for byte in 0 ..< 4:
    output[byteIndex + byte] = uint8((pointX shr (8 * byte)) and 0xFF'u32)
    output[byteIndex + 4 + byte] = uint8((pointY shr (8 * byte)) and 0xFF'u32)

proc bresenhams_line*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "bresenhams_line".} =
  if length != 4 or values == nil: return -1
  let x0 = values[0]
  let y0 = values[1]
  let x1 = values[2]
  let y1 = values[3]
  if x0 < -1_000_000 or x0 > 1_000_000 or y0 < -1_000_000 or
      y0 > 1_000_000 or x1 < -1_000_000 or x1 > 1_000_000 or
      y1 < -1_000_000 or y1 > 1_000_000:
    return -1

  let dx = abs(x1 - x0)
  let absDy = abs(y1 - y0)
  let steps = max(dx, absDy)
  if steps > 4_096: return -1
  let count = steps + 1
  if output == nil or outputCapacity < csize_t(count * 8): return -2

  var x = x0
  var y = y0
  let sx = if x0 < x1: 1'i64 else: -1'i64
  let sy = if y0 < y1: 1'i64 else: -1'i64
  let dy = -absDy
  var error = dx + dy
  var pointIndex = 0'i64
  while true:
    writePoint(output, pointIndex, x, y)
    inc pointIndex
    if x == x1 and y == y1: break
    let doubledError = 2 * error
    if doubledError >= dy:
      error += dy
      x += sx
    if doubledError <= dx:
      error += dx
      y += sy
  count
