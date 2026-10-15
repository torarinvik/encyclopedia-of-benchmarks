const MaxObservations = 64
const MaxEpochs = 10000
const InvalidResult = -1.0e300

proc linear_regression_gradient_descent*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "linear_regression_gradient_descent".} =
  if values == nil or length < 7 or length > csize_t(131) or length mod 2 == 0: return InvalidResult
  let count = values[0]
  let rateMicrounits = values[1]
  let epochs = values[2]
  if count < 2 or count > MaxObservations or length != csize_t(3 + 2 * count) or
      rateMicrounits < 1 or rateMicrounits > 1000 or epochs < 1 or epochs > MaxEpochs: return InvalidResult
  for index in 0 ..< int(count):
    let x = values[3 + 2 * index]
    let y = values[4 + 2 * index]
    if x < -10 or x > 10 or y < -100 or y > 100: return InvalidResult

  let alpha = float64(rateMicrounits) / 1_000_000.0
  let scale = alpha / float64(count)
  var slope = 0.0
  var intercept = 0.0
  for epoch in 0 ..< int(epochs):
    var slopeGradient = 0.0
    var interceptGradient = 0.0
    for index in 0 ..< int(count):
      let x = float64(values[3 + 2 * index])
      let y = float64(values[4 + 2 * index])
      let error = slope * x + intercept - y
      slopeGradient += error * x
      interceptGradient += error
    slope -= scale * slopeGradient
    intercept -= scale * interceptGradient
  return slope
