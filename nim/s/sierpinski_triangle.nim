proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc emitSegment(output: ptr UncheckedArray[uint8], position: var int,
                 x0, y0, x1, y1: int64) =
  for value in [x0, y0, x1, y1]:
    writeI64Le(output, position, value)
    position += 8

proc drawTriangle(output: ptr UncheckedArray[uint8], position: var int,
                  x1, y1, x2, y2, x3, y3, depth: int64) =
  emitSegment(output, position, x1, y1, x2, y2)
  emitSegment(output, position, x2, y2, x3, y3)
  emitSegment(output, position, x3, y3, x1, y1)
  if depth == 0: return
  let abx = (x1 + x2) div 2
  let aby = (y1 + y2) div 2
  let acx = (x1 + x3) div 2
  let acy = (y1 + y3) div 2
  let bcx = (x2 + x3) div 2
  let bcy = (y2 + y3) div 2
  drawTriangle(output, position, x1, y1, abx, aby, acx, acy, depth - 1)
  drawTriangle(output, position, x2, y2, abx, aby, bcx, bcy, depth - 1)
  drawTriangle(output, position, x3, y3, bcx, bcy, acx, acy, depth - 1)

proc sierpinski_triangle*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sierpinski_triangle".} =
  if input == nil or length != 1: return -1
  let depth = input[0]
  if depth < 0 or depth > 4: return -1
  var calls = 1
  for _ in 0 ..< int(depth): calls = calls * 3 + 1
  let needed = calls * 96
  if needed > 11616: return -1
  if output == nil or capacity < csize_t(needed): return -2
  var position = 0
  drawTriangle(output, position, -2800, -2000, 0, 2800, 2800, -2000, depth)
  int64(needed)
