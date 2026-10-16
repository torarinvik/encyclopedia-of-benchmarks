import std/math

proc objective(x1, x2, target1, target2: float64): float64 =
  let dx = x1 - target1
  let dy = x2 - target2
  -(dx * dx + dy * dy)

proc gauss_optimization*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "gauss_optimization".} =
  if values == nil or length != 7: return -1
  for i in 0 ..< int(length):
    if classify(values[i]) == fcNan or classify(values[i]) == fcInf: return -1
  if values[0] notin [2.0, 3.0, 4.0] or values[1] < 0.25 or values[1] > 4.0 or values[2] < 1e-6 or values[2] > 2.0: return -1
  for i in 3 ..< 7:
    if values[i] < -8.0 or values[i] > 8.0: return -1
  if output == nil or capacity < 2: return -2

  let factor = values[0]
  var step = values[1]
  let epsilon = values[2]
  var x1 = values[3]
  var x2 = values[4]
  let target1 = values[5]
  let target2 = values[6]
  var error = 1.0
  var iteration = 0
  while abs(error) > epsilon and iteration < 256:
    let current = objective(x1, x2, target1, target2)
    var best = objective(x1, x2 - step, target1, target2)
    var choice = 0
    var candidate = objective(x1, x2 + step, target1, target2)
    if candidate > best: best = candidate; choice = 1
    candidate = objective(x1 - step, x2, target1, target2)
    if candidate > best: best = candidate; choice = 2
    candidate = objective(x1 + step, x2, target1, target2)
    if candidate > best: best = candidate; choice = 3
    error = best - current
    case choice
    of 0: x2 -= step
    of 1: x2 += step
    of 2: x1 -= step
    else: x1 += step
    step /= factor
    inc iteration
  if abs(error) > epsilon: return -1
  output[0] = x1
  output[1] = x2
  2
