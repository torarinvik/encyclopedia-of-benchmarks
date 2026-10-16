## Bounded Gauss-Legendre quadrature using the pinned Fortran tables.
const InvalidResult = -1.0e300

proc gaussian_legendre*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "gaussian_legendre".} =
  if values == nil or length != 7: return InvalidResult
  if values[0] < 1 or values[0] > 5 or values[1] < -5000 or values[1] > 5000: return InvalidResult
  if values[2] < -5000 or values[2] > 5000: return InvalidResult
  for index in 3 ..< 7:
    if values[index] < -10000 or values[index] > 10000: return InvalidResult

  let order = int(values[0])
  var nodes: array[5, float64]
  var weights: array[5, float64]
  case order
  of 1:
    nodes[0] = 0.0; weights[0] = 2.0
  of 2:
    nodes[0] = -0.5773502692; nodes[1] = 0.5773502692
    weights[0] = 1.0; weights[1] = 1.0
  of 3:
    nodes[0] = -0.7745966692; nodes[1] = 0.0; nodes[2] = 0.7745966692
    weights[0] = 0.5555555556; weights[1] = 0.8888888889; weights[2] = 0.5555555556
  of 4:
    nodes[0] = -0.8611363116; nodes[1] = -0.3399810436
    nodes[2] = 0.3399810436; nodes[3] = 0.8611363116
    weights[0] = 0.3478548451; weights[1] = 0.6521451549
    weights[2] = 0.6521451549; weights[3] = 0.3478548451
  else:
    nodes[0] = -0.9061798459; nodes[1] = -0.5384693101; nodes[2] = 0.0
    nodes[3] = 0.5384693101; nodes[4] = 0.9061798459
    weights[0] = 0.2369268851; weights[1] = 0.4786286705
    weights[2] = 0.5688888889; weights[3] = 0.4786286705; weights[4] = 0.2369268851

  let a = float64(values[1]) / 1000.0
  let b = float64(values[2]) / 1000.0
  let c0 = float64(values[3]) / 1000.0
  let c1 = float64(values[4]) / 1000.0
  let c2 = float64(values[5]) / 1000.0
  let c3 = float64(values[6]) / 1000.0
  var weightedSum = 0.0
  for index in 0 ..< order:
    let x = (b + a) / 2.0 + (b - a) * nodes[index] / 2.0
    let x2 = x * x
    let x3 = x2 * x
    let functionValue = c0 + c1 * x + c2 * x2 + c3 * x3
    weightedSum += weights[index] * functionValue
  weightedSum * (b - a) / 2.0
