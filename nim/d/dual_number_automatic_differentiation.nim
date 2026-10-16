const MaxPower = 8
const InvalidResult = -1.0e300

proc dual_number_automatic_differentiation*(position, power, order: float64): float64
    {.cdecl, exportc: "dual_number_automatic_differentiation".} =
  if position < -1.0 or position > 1.0 or power < 0.0 or power > float64(MaxPower) or
      order < 0.0 or order > float64(MaxPower): return InvalidResult
  let exponent = int(power)
  let derivativeOrder = int(order)
  if power != float64(exponent) or order != float64(derivativeOrder) or derivativeOrder > exponent:
    return InvalidResult

  var coefficients: array[MaxPower + 1, float64]
  coefficients[0] = 1.0
  for step in 0 ..< exponent:
    var next: array[MaxPower + 1, float64]
    next[0] = coefficients[0] * position
    for degree in 1 .. step + 1:
      next[degree] = coefficients[degree] * position + coefficients[degree - 1]
    coefficients = next
  result = coefficients[derivativeOrder]
  for factor in 2 .. derivativeOrder:
    result *= float64(factor)
