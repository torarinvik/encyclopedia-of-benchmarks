const maxN = 64
const inputMax = 129

proc pointHalf(x, y: int64): int =
  if y < 0: return 0
  if y == 0 and x >= 0: return 1
  2

proc pointLess(ax, ay, bx, by: int64): bool =
  let ah = pointHalf(ax, ay)
  let bh = pointHalf(bx, by)
  if ah != bh: return ah < bh
  let cross = ax * by - ay * bx
  if cross != 0: return cross > 0
  let ar = ax * ax + ay * ay
  let br = bx * bx + by * by
  if ar != br: return ar < br
  if ax != bx: return ax < bx
  ay < by

proc storeLe(output: ptr UncheckedArray[uint8], at: csize_t, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[at + csize_t(byte)] = uint8((bits shr (8 * byte)) and 255)

proc sort_points_by_argument*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "sort_points_by_argument".} =
  if input == nil or length < 1 or length > csize_t(inputMax): return -1
  let nr = input[0]
  if nr < 1 or nr > maxN or length != csize_t(1 + 2 * nr): return -1
  let n = int(nr)
  var xs: array[maxN, int64]
  var ys: array[maxN, int64]
  for i in 0 ..< n:
    let x = input[csize_t(1 + 2 * i)]
    let y = input[csize_t(2 + 2 * i)]
    if x < -1_000_000_000 or x > 1_000_000_000 or y < -1_000_000_000 or y > 1_000_000_000: return -1
    xs[i] = x
    ys[i] = y
  let required = csize_t(16 * n)
  if output == nil or capacity < required: return -2
  for i in 1 ..< n:
    let itemX = xs[i]
    let itemY = ys[i]
    var j = i
    while j > 0 and pointLess(itemX, itemY, xs[j - 1], ys[j - 1]):
      xs[j] = xs[j - 1]
      ys[j] = ys[j - 1]
      dec j
    xs[j] = itemX
    ys[j] = itemY
  for i in 0 ..< n:
    storeLe(output, csize_t(16 * i), xs[i])
    storeLe(output, csize_t(16 * i + 8), ys[i])
  int64(required)
