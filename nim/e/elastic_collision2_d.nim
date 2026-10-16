import math

proc elastic_collision2_d*(v: ptr int64, n: uint64): int64 {.cdecl, exportc.} =
  if v == nil or n != 12:
    return -1
  let a = cast[ptr UncheckedArray[int64]](v)
  for i in [0, 1, 6, 7]:
    if a[i] < -200000 or a[i] > 200000:
      return -1
  for i in [2, 3, 8, 9]:
    if a[i] < -5000 or a[i] > 5000:
      return -1
  if a[4] < 1000 or a[4] > 100000 or a[10] < 1000 or a[10] > 100000 or
      a[5] < 1 or a[5] > 10000 or a[11] < 1 or a[11] > 10000:
    return -1
  let dx = float64(a[6] - a[0])
  let dy = float64(a[7] - a[1])
  let dist = hypot(dx, dy)
  if dist == 0:
    return -1
  var ox = float64(a[2])
  var oy = float64(a[3])
  if not (dist < float64(a[5] + a[11])):
    let nx = dx / dist
    let ny = dy / dist
    let rv = float64(a[8] - a[2]) * nx + float64(a[9] - a[3]) * ny
    if rv <= 0:
      let j = -2.0 * rv / (1.0 / float64(a[4]) + 1.0 / float64(a[10]))
      ox -= j * nx / float64(a[4])
      oy -= j * ny / float64(a[4])
  let qx = int64(floor(ox + 0.5))
  let qy = int64(floor(oy + 0.5))
  if qx < -32768 or qx > 32767 or qy < -32768 or qy > 32767:
    return -1
  ((qx and 0xffff) shl 16) or (qy and 0xffff)
