import std/math

const CoefficientLimit = 1_000_000'i64
const InvalidResult = -1.0e300

proc quadratic_equation_solver_complex_roots*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "quadratic_equation_solver_complex_roots".} =
  if values == nil or length != 4: return InvalidResult
  let a = values[0]
  let b = values[1]
  let c = values[2]
  let component = values[3]
  if a == 0 or a < -CoefficientLimit or a > CoefficientLimit or
      b < -CoefficientLimit or b > CoefficientLimit or
      c < -CoefficientLimit or c > CoefficientLimit or
      component < 0 or component > 3: return InvalidResult

  let discriminant = b * b - 4 * a * c
  let denominator = 2.0 * float64(a)
  if discriminant > 0:
    if component >= 2: return InvalidResult
    let squareRoot = sqrt(float64(discriminant))
    if component == 0: return (-float64(b) + squareRoot) / denominator
    return (-float64(b) - squareRoot) / denominator
  if discriminant == 0:
    if component == 0: return -float64(b) / denominator
    return InvalidResult

  if component < 2: return -float64(b) / denominator
  let imaginary = sqrt(float64(-discriminant)) / denominator
  if component == 2: return imaginary
  -imaginary
