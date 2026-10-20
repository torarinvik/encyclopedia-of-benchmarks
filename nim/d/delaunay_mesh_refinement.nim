import std/math

const
  InputLength = 7
  MaxOutputBytes = 152
  CoordinateScale = 1_000_000'i64

proc orient(ax, ay, bx, by, cx, cy: int64): int64 =
  (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

proc roundRatioAway(numerator, denominator: int64): int64 =
  let magnitude = if numerator < 0: -numerator else: numerator
  let rounded = (magnitude + denominator div 2) div denominator
  if numerator < 0: -rounded else: rounded

proc putI64(output: var array[MaxOutputBytes, uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255)
    bits = bits shr 8

proc delaunayMeshRefinement*(values: ptr UncheckedArray[int64], length: csize_t,
                             output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "delaunay_mesh_refinement".} =
  if values.isNil or length != csize_t(InputLength) or values[0] != 3: return -1
  var x, y: array[3, int64]
  for i in 0 ..< 3:
    x[i] = values[1 + 2 * i]
    y[i] = values[2 + 2 * i]
    if x[i] < -100 or x[i] > 100 or y[i] < -100 or y[i] > 100: return -1
    for j in 0 ..< i:
      if x[i] == x[j] and y[i] == y[j]: return -1
  let area2 = orient(x[0], y[0], x[1], y[1], x[2], y[2])
  if area2 <= 0: return -1
  for i in 0 ..< 3:
    let j = (i + 1) mod 3
    let k = (i + 2) mod 3
    let ux = x[j] - x[i]
    let uy = y[j] - y[i]
    let vx = x[k] - x[i]
    let vy = y[k] - y[i]
    if ux * vx + uy * vy <= 0: return -1

  let len01 = sqrt(float64((x[1]-x[0])*(x[1]-x[0]) + (y[1]-y[0])*(y[1]-y[0])))
  let len12 = sqrt(float64((x[2]-x[1])*(x[2]-x[1]) + (y[2]-y[1])*(y[2]-y[1])))
  let len20 = sqrt(float64((x[0]-x[2])*(x[0]-x[2]) + (y[0]-y[2])*(y[0]-y[2])))
  let shortest = min(len01, min(len12, len20))
  let ratio = len01 * len12 * len20 / (2.0 * float64(area2) * shortest)
  let beta = 1.0 / (2.0 * sin(PI / 9.0))
  let refine = ratio > beta * (1.0 + 1e-12)

  var staged: array[MaxOutputBytes, uint8]
  putI64(staged, 0, if refine: 4 else: 3)
  for i in 0 ..< 3:
    putI64(staged, 8 + 16 * i, x[i] * CoordinateScale)
    putI64(staged, 16 + 16 * i, y[i] * CoordinateScale)
  if refine:
    let ax = x[0]
    let ay = y[0]
    let bax = x[1] - ax
    let bay = y[1] - ay
    let cax = x[2] - ax
    let cay = y[2] - ay
    let denominator = 2 * (bax * cay - bay * cax)
    let balenSq = bax * bax + bay * bay
    let calenSq = cax * cax + cay * cay
    let centerXNum = ax * denominator + cay * balenSq - bay * calenSq
    let centerYNum = ay * denominator + bax * calenSq - cax * balenSq
    putI64(staged, 56, roundRatioAway(centerXNum * CoordinateScale, denominator))
    putI64(staged, 64, roundRatioAway(centerYNum * CoordinateScale, denominator))
    let words = [3'i64, 0, 1, 3, 1, 2, 3, 2, 0, 3]
    for i, word in words: putI64(staged, 72 + 8 * i, word)
  else:
    let words = [1'i64, 0, 1, 2]
    for i, word in words: putI64(staged, 56 + 8 * i, word)
  let required = if refine: MaxOutputBytes else: 88
  if output.isNil or capacity < csize_t(required): return -2
  for i in 0 ..< required: output[i] = staged[i]
  int64(required)
