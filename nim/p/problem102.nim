## Count triangles whose strict interior contains the origin.
const MaxValues = 6_000
const MinCoord = -1_000'i64
const MaxCoord = 1_000'i64

proc originInside(x1, y1, x2, y2, x3, y3: int64): int64 =
  let abx = x2 - x1
  let aby = y2 - y1
  let acx = x3 - x1
  let acy = y3 - y1
  var denominator = acx * aby - acy * abx
  var numeratorA = -(x1 * aby - y1 * abx)
  var numeratorB = x1 * acy - y1 * acx
  if denominator == 0: return -1
  if denominator < 0:
    denominator = -denominator
    numeratorA = -numeratorA
    numeratorB = -numeratorB
  if numeratorA > 0 and numeratorB > 0 and numeratorA + numeratorB < denominator: 1 else: 0

proc problem102*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "problem102".} =
  if input == nil or length < csize_t(6) or length > csize_t(MaxValues) or length mod csize_t(6) != 0:
    return -1
  for index in 0 ..< int(length):
    if input[index] < MinCoord or input[index] > MaxCoord: return -1
  var count = 0'i64
  var offset = 0
  while offset < int(length):
    let inside = originInside(input[offset], input[offset + 1], input[offset + 2], input[offset + 3], input[offset + 4], input[offset + 5])
    if inside < 0: return -1
    count += inside
    offset += 6
  count
