const MaxInput = 67
const MaxOutput = 504
const MaxHeight = 63
const MaxSide = 32

type MinPlusContext = object
  concave, arbitrary: array[MaxSide, int64]
  n, m, height: int
  yMin, yMax: array[MaxHeight, int]
  xMin, xMax: array[MaxSide, int]
  result: array[MaxHeight, int64]

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc blockRows(c: var MinPlusContext, x1, x2, y1, y2, row1, row2, q1, q2: int) =
  if row1 > row2: return
  let mid = row1 + (row2 - row1) div 2
  let x = x1 + mid
  var best = high(int64)
  var bestQ = q1
  for q in q1 .. q2:
    let y = y2 - q
    let value = c.arbitrary[y] + c.concave[x - y]
    if value < best: best = value; bestQ = q
  if best < c.result[x]: c.result[x] = best
  if row1 < mid: blockRows(c, x1, x2, y1, y2, row1, mid - 1, q1, bestQ)
  if mid < row2: blockRows(c, x1, x2, y1, y2, mid + 1, row2, bestQ, q2)

proc scanRectangle(c: var MinPlusContext, x1, x2, y1, y2: int) =
  for x in x1 .. x2:
    let low = max(c.yMin[x], y1)
    let highY = min(c.yMax[x], y2)
    if low <= highY:
      for y in low .. highY:
        let value = c.arbitrary[y] + c.concave[x - y]
        if value < c.result[x]: c.result[x] = value

proc partition(c: var MinPlusContext, x1, x2, y1, y2: int) =
  if x1 > x2 or y1 > y2: return
  if c.yMax[x1] >= y2 and y1 >= c.yMin[x2]:
    blockRows(c, x1, x2, y1, y2, 0, x2 - x1, 0, y2 - y1)
    return
  if (x2 - x1) * (y2 - y1) < 1000:
    scanRectangle(c, x1, x2, y1, y2)
    return
  if x2 - x1 > y2 - y1:
    let mid = (x1 + x2) div 2
    let leftY2 = min(c.yMax[mid], y2)
    if y1 <= leftY2: partition(c, x1, mid, y1, leftY2)
    let rightY1 = max(c.yMin[mid], y1)
    if rightY1 <= y2: partition(c, mid + 1, x2, rightY1, y2)
  else:
    let mid = (y1 + y2) div 2
    let leftX2 = min(c.xMax[mid], x2)
    if x1 <= leftX2: partition(c, x1, leftX2, y1, mid)
    let rightX1 = max(c.xMin[mid], x1)
    if rightX1 <= x2: partition(c, rightX1, x2, mid + 1, y2)

proc min_plus_convolution_concave_arbitrary*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "min_plus_convolution_concave_arbitrary".} =
  if input == nil or length < 4 or length > csize_t(MaxInput): return -1
  let n0 = input[0]; let m0 = input[1]
  if n0 < 1 or n0 > MaxSide or m0 < 1 or m0 > MaxSide: return -1
  let n = int(n0); let m = int(m0)
  if int(length) != 2 + n + m: return -1
  var c: MinPlusContext
  c.n = m; c.m = n; c.height = n + m - 1
  for i in 0 ..< n + m:
    let value = input[2 + i]
    if value < 0 or value > 1_000_000_000: return -1
    if i < n: c.concave[i] = value else: c.arbitrary[i - n] = value
  for i in 0 ..< max(0, n - 2):
    if c.concave[i + 1] - c.concave[i] < c.concave[i + 2] - c.concave[i + 1]: return -1
  let bytes = 8 * c.height
  if bytes > MaxOutput: return -1
  if output == nil or int(capacity) < bytes: return -2
  for x in 0 ..< c.height:
    c.yMin[x] = if x >= n: x - n + 1 else: 0
    c.yMax[x] = min(m - 1, x)
    c.result[x] = high(int64)
  for y in 0 ..< m:
    c.xMin[y] = y
    c.xMax[y] = n - 1 + y
  partition(c, 0, c.height - 1, 0, m - 1)
  for i in 0 ..< c.height: storeI64Le(output, 8 * i, c.result[i])
  int64(bytes)
