const MaxPolygons = 32
const MaxVerticesPerPolygon = 128
const MaxTotalVertices = 512
const MaxInputValues = 1 + MaxPolygons + 2 * MaxTotalVertices
const CoordinateLimit = 1_000_000'i64
const AreaOffset = 1_000_000_007'i64

proc area_of_polygon_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "area_of_polygon_benchmark".} =
  if length < 1 or length > MaxInputValues.csize_t: return -1
  let polygonCountValue = values[0]
  if polygonCountValue < 0 or polygonCountValue > MaxPolygons.int64: return -1
  let polygonCount = polygonCountValue.int
  var cursor = 1
  var totalVertices = 0
  for polygon in 0 ..< polygonCount:
    discard polygon
    if cursor >= length.int: return -1
    let vertexCountValue = values[cursor]
    inc cursor
    if vertexCountValue < 3 or vertexCountValue > MaxVerticesPerPolygon.int64: return -1
    let vertexCount = vertexCountValue.int
    if totalVertices + vertexCount > MaxTotalVertices or 2 * vertexCount > length.int - cursor: return -1
    for vertex in 0 ..< vertexCount:
      let x = values[cursor + 2 * vertex]
      let y = values[cursor + 2 * vertex + 1]
      if x < -CoordinateLimit or x > CoordinateLimit or y < -CoordinateLimit or y > CoordinateLimit: return -1
    cursor += 2 * vertexCount
    totalVertices += vertexCount
  if cursor != length.int: return -1

  cursor = 1
  var checksum = 0'i64
  for polygon in 0 ..< polygonCount:
    let vertexCount = values[cursor].int
    inc cursor
    let points = cursor
    var previousX = values[points + 2 * (vertexCount - 1)]
    var previousY = values[points + 2 * (vertexCount - 1) + 1]
    var crossSum = 0'i64
    for vertex in 0 ..< vertexCount:
      let currentX = values[points + 2 * vertex]
      let currentY = values[points + 2 * vertex + 1]
      crossSum += previousX * currentY - currentX * previousY
      previousX = currentX
      previousY = currentY
    checksum += (polygon + 1).int64 * (abs(crossSum) + AreaOffset)
    cursor += 2 * vertexCount
  checksum
