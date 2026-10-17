const MaxInputLength = 66
const InvalidResult = -1'i64

proc absI64(value: int64): int64 =
  if value < 0: -value else: value

proc gcdI64(a, b: int64): int64 =
  var x = a
  var y = b
  while y != 0:
    let temp = y
    y = x mod y
    x = temp
  x

proc cross(x1, y1, x2, y2: int64): int64 =
  x1 * y2 - x2 * y1

proc polygon_points*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "polygon_points".} =
  if values == nil or length < 1 or length > MaxInputLength: return InvalidResult
  let rawN = values[0]
  if rawN < 3 or rawN > 32 or length != csize_t(1 + 2 * rawN): return InvalidResult
  let n = int(rawN)
  for i in 0 ..< 2 * n:
    if values[1 + i] < -1000 or values[1 + i] > 1000: return InvalidResult

  let originX = values[1]
  let originY = values[2]
  var doubledArea = 0'i64
  for i in 2 ..< n:
    let x1 = values[1 + 2 * i] - originX
    let y1 = values[2 + 2 * i] - originY
    let x2 = values[1 + 2 * (i - 1)] - originX
    let y2 = values[2 + 2 * (i - 1)] - originY
    doubledArea += cross(x1, y1, x2, y2)
  let area = absI64(doubledArea div 2)

  var boundary = rawN
  for i in 0 ..< n:
    let next = (i + 1) mod n
    let dx = values[1 + 2 * i] - values[1 + 2 * next]
    let dy = values[2 + 2 * i] - values[2 + 2 * next]
    boundary += absI64(gcdI64(dx, dy)) - 1
  area + 1 - boundary div 2
