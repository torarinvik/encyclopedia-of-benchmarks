const
  MaxLines = 32
  MaxQueries = 32
  MaxLength = 99
  Invalid = low(int64)

type Line = object
  slope, intercept: int64

proc value(line: Line, x: int64): int64 = line.slope * x + line.intercept

proc redundant(a, b, c: Line): bool =
  (b.intercept - a.intercept) * (b.slope - c.slope) >=
    (c.intercept - b.intercept) * (a.slope - b.slope)

proc monotone_convex_hull_trick*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "monotone_convex_hull_trick".} =
  if values == nil or length < 2 or length > csize_t(MaxLength): return Invalid
  let lineCountValue = values[0]
  let queryCountValue = values[1]
  if lineCountValue < 1 or lineCountValue > MaxLines or queryCountValue < 0 or queryCountValue > MaxQueries: return Invalid
  let lineCount = int(lineCountValue)
  let queryCount = int(queryCountValue)
  if length != csize_t(2 + 2 * lineCount + queryCount): return Invalid

  var hull: array[MaxLines, Line]
  var hullCount = 0
  var previousSlope = high(int64)
  var cursor = 2
  for _ in 0 ..< lineCount:
    let line = Line(slope: values[cursor], intercept: values[cursor + 1])
    cursor += 2
    if line.slope < -1000 or line.slope > 1000 or line.intercept < -10000 or line.intercept > 10000 or line.slope >= previousSlope: return Invalid
    previousSlope = line.slope
    while hullCount >= 2 and redundant(hull[hullCount - 2], hull[hullCount - 1], line): dec hullCount
    hull[hullCount] = line
    inc hullCount

  var front = 0
  var previousX = low(int64)
  var checksum = 0'i64
  for i in 0 ..< queryCount:
    let x = values[cursor + i]
    if x < -1000 or x > 1000 or (i > 0 and x < previousX): return Invalid
    previousX = x
    while front + 1 < hullCount and value(hull[front + 1], x) <= value(hull[front], x): inc front
    checksum += int64(i + 1) * value(hull[front], x)
  checksum
