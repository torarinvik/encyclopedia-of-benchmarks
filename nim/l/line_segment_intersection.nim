proc orient(a, b, c: tuple[x, y: int64]): int64 =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

proc onSegment(a, b, p: tuple[x, y: int64]): bool =
  min(a.x, b.x) <= p.x and p.x <= max(a.x, b.x) and
    min(a.y, b.y) <= p.y and p.y <= max(a.y, b.y)

proc line_segment_intersection*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "line_segment_intersection".} =
  discard output
  discard outputCapacity
  if length != 8 or values == nil: return -1
  for index in 0 ..< 8:
    if values[index] < -10_000 or values[index] > 10_000: return -1

  let a = (x: values[0], y: values[1])
  let b = (x: values[2], y: values[3])
  let c = (x: values[4], y: values[5])
  let d = (x: values[6], y: values[7])
  let abC = orient(a, b, c)
  let abD = orient(a, b, d)
  let cdA = orient(c, d, a)
  let cdB = orient(c, d, b)

  if abC == 0 and onSegment(a, b, c): return 1
  if abD == 0 and onSegment(a, b, d): return 1
  if cdA == 0 and onSegment(c, d, a): return 1
  if cdB == 0 and onSegment(c, d, b): return 1
  if ((abC > 0 and abD < 0) or (abC < 0 and abD > 0)) and
      ((cdA > 0 and cdB < 0) or (cdA < 0 and cdB > 0)):
    return 1
  0
