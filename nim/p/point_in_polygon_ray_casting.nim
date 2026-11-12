proc point_in_polygon_ray_casting*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "point_in_polygon_ray_casting".} =
  if values == nil or length < 9 or length > 131: return -1
  let n = values[0]
  if n < 3 or n > 64 or length != csize_t(3 + 2 * n): return -1
  let qx = values[1]
  let qy = values[2]
  const bound = 1_000_000'i64
  if qx < -bound or qx > bound or qy < -bound or qy > bound: return -1
  for i in 3 ..< int(length):
    if values[i] < -bound or values[i] > bound: return -1

  var inside = false
  for i in 0 ..< int(n):
    let j = (i + 1) mod int(n)
    let ax = values[3 + 2 * i]
    let ay = values[4 + 2 * i]
    let bx = values[3 + 2 * j]
    let by = values[4 + 2 * j]
    let turn = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax)
    if turn == 0 and qx >= min(ax, bx) and qx <= max(ax, bx) and
        qy >= min(ay, by) and qy <= max(ay, by): return 1
    if (ay > qy) != (by > qy) and ((by > ay and turn > 0) or (by < ay and turn < 0)):
      inside = not inside
  if inside: 1 else: 0
