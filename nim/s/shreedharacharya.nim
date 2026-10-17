import std/math

const MaxCoefficient = 1_000_000.0
const MinAbsLeadingCoefficient = 0.000001

proc shreedharacharya*(input: ptr UncheckedArray[float64], inputLen: csize_t,
                       output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "shreedharacharya".} =
  if input.isNil or inputLen != csize_t(3): return -1
  let a = input[0]
  let b = input[1]
  let c = input[2]
  if a != a or b != b or c != c or
      a < -MaxCoefficient or a > MaxCoefficient or
      (a > -MinAbsLeadingCoefficient and a < MinAbsLeadingCoefficient) or
      b < -MaxCoefficient or b > MaxCoefficient or
      c < -MaxCoefficient or c > MaxCoefficient: return -1

  let discriminant = b * b - 4.0 * a * c
  var roots: array[2, float64]
  var count = 0
  if discriminant == 0.0:
    roots[count] = -b / (2.0 * a)
    inc count
  elif discriminant > 0.0:
    let squareRoot = sqrt(discriminant)
    let denominator = 2.0 * a
    roots[count] = (-b + squareRoot) / denominator
    inc count
    roots[count] = (-b - squareRoot) / denominator
    inc count
  for index in 0 ..< count:
    if roots[index] != roots[index]: return -1
  if output.isNil or outputCapacity < csize_t(count): return -2
  for index in 0 ..< count:
    output[index] = roots[index]
  int64(count)
