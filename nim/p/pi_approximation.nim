proc pi_approximation*(points: ptr UncheckedArray[float64], point_count: csize_t): float64
    {.cdecl, exportc: "pi_approximation".} =
  var inside = 0'i64
  for index in 0 ..< int(point_count):
    let x = points[2 * index]
    let y = points[2 * index + 1]
    if x * x + y * y <= 1.0: inc inside
  4.0 * float64(inside) / float64(point_count)
