proc same(a, b: tuple[x, y: int64]): bool = a.x == b.x and a.y == b.y
proc cross(a, b, c: tuple[x, y: int64]): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
proc onSegment(a, b, p: tuple[x, y: int64]): bool =
  cross(a, b, p) == 0 and min(a.x, b.x) <= p.x and p.x <= max(a.x, b.x) and
    min(a.y, b.y) <= p.y and p.y <= max(a.y, b.y)
proc writePoint(output: ptr UncheckedArray[uint8], capacity: csize_t, x, y: float64): int64 =
  if output == nil or capacity < 16: return -2
  let xBits = cast[uint64](x)
  let yBits = cast[uint64](y)
  for byte in 0 ..< 8:
    output[byte] = uint8((xBits shr (8 * byte)) and 0xFF'u64)
    output[8 + byte] = uint8((yBits shr (8 * byte)) and 0xFF'u64)
  1

proc line_intersection*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "line_intersection".} =
  if length != 9 or values == nil: return -1
  for index in 0 ..< 8:
    if values[index] < -10_000 or values[index] > 10_000: return -1
  if values[8] != 0 and values[8] != 1: return -1
  let p1 = (x: values[0], y: values[1])
  let p2 = (x: values[2], y: values[3])
  let q1 = (x: values[4], y: values[5])
  let q2 = (x: values[6], y: values[7])
  let segments = values[8] == 1
  let pPoint = same(p1, p2)
  let qPoint = same(q1, q2)
  if not segments and (pPoint or qPoint): return -1
  if segments and pPoint and qPoint:
    return if same(p1, q1): writePoint(output, outputCapacity, float64(p1.x), float64(p1.y)) else: 0
  if segments and pPoint:
    return if onSegment(q1, q2, p1): writePoint(output, outputCapacity, float64(p1.x), float64(p1.y)) else: 0
  if segments and qPoint:
    return if onSegment(p1, p2, q1): writePoint(output, outputCapacity, float64(q1.x), float64(q1.y)) else: 0
  let denominator = (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x)
  if denominator == 0: return 0
  let determinantP = p1.x * p2.y - p1.y * p2.x
  let determinantQ = q1.x * q2.y - q1.y * q2.x
  let numeratorX = determinantP * (q1.x - q2.x) - (p1.x - p2.x) * determinantQ
  let numeratorY = determinantP * (q1.y - q2.y) - (p1.y - p2.y) * determinantQ
  if segments:
    let den = abs(denominator)
    let x = if denominator < 0: -numeratorX else: numeratorX
    let y = if denominator < 0: -numeratorY else: numeratorY
    let minX = max(min(p1.x, p2.x), min(q1.x, q2.x))
    let maxX = min(max(p1.x, p2.x), max(q1.x, q2.x))
    let minY = max(min(p1.y, p2.y), min(q1.y, q2.y))
    let maxY = min(max(p1.y, p2.y), max(q1.y, q2.y))
    if x < minX * den or x > maxX * den or y < minY * den or y > maxY * den: return 0
    return writePoint(output, outputCapacity, float64(x) / float64(den), float64(y) / float64(den))
  writePoint(output, outputCapacity, float64(numeratorX) / float64(denominator),
    float64(numeratorY) / float64(denominator))
