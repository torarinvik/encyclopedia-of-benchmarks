## Area covered by the union of two axis-aligned rectangles.
const CoordinateLimit = 1_000_000_000'i64

proc rectangle_union_area*(coordinates: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rectangle_union_area".} =
  if coordinates == nil or length != 8: return -1
  for index in 0 ..< 8:
    if coordinates[index] < -CoordinateLimit or coordinates[index] > CoordinateLimit: return -1
  let ax1 = coordinates[0]
  let ay1 = coordinates[1]
  let ax2 = coordinates[2]
  let ay2 = coordinates[3]
  let bx1 = coordinates[4]
  let by1 = coordinates[5]
  let bx2 = coordinates[6]
  let by2 = coordinates[7]
  if ax1 >= ax2 or ay1 >= ay2 or bx1 >= bx2 or by1 >= by2: return -1
  let areaA = (ax2 - ax1) * (ay2 - ay1)
  let areaB = (bx2 - bx1) * (by2 - by1)
  let overlapWidth = min(ax2, bx2) - max(ax1, bx1)
  let overlapHeight = min(ay2, by2) - max(ay1, by1)
  let overlap = if overlapWidth > 0 and overlapHeight > 0: overlapWidth * overlapHeight else: 0'i64
  areaA + areaB - overlap
