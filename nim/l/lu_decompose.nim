import std/math

const MaxInputLength = 18

proc roundedMultiply(left, right: float64): float64 {.noinline.} = left * right
proc roundedAdd(left, right: float64): float64 {.noinline.} = left + right
proc roundedSubtract(left, right: float64): float64 {.noinline.} = left - right
proc roundedDivide(left, right: float64): float64 {.noinline.} = left / right

proc exactInteger(value: float64, minimum, maximum: int64): bool =
  if classify(value) in {fcNan, fcInf, fcNegInf}: return false
  if value < float64(minimum) or value > float64(maximum): return false
  float64(int64(value)) == value

proc lu_decompose*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "lu_decompose".} =
  if input == nil or inputLength < 1 or inputLength > MaxInputLength.csize_t: return -1
  if not exactInteger(input[0], 1, 4): return -1
  let n = int(input[0])
  if inputLength != csize_t(1 + n * n): return -1
  var matrix: array[16, float64]
  for i in 0 ..< n * n:
    if not exactInteger(input[i + 1], -8, 8): return -1
    matrix[i] = input[i + 1]
  var lower: array[16, float64]
  var upper: array[16, float64]
  for row in 0 ..< n:
    for column in row ..< n:
      var sum = 0.0
      for index in 0 ..< row:
        let product = roundedMultiply(lower[row * n + index], upper[index * n + column])
        sum = roundedAdd(sum, product)
      upper[row * n + column] = roundedSubtract(matrix[row * n + column], sum)
    let pivot = upper[row * n + row]
    if pivot == 0.0 or classify(pivot) in {fcNan, fcInf, fcNegInf}: return -1
    lower[row * n + row] = 1.0
    for lowerRow in row + 1 ..< n:
      var sum = 0.0
      for index in 0 ..< row:
        let product = roundedMultiply(lower[lowerRow * n + index], upper[index * n + row])
        sum = roundedAdd(sum, product)
      let numerator = roundedSubtract(matrix[lowerRow * n + row], sum)
      let value = roundedDivide(numerator, pivot)
      if classify(value) in {fcNan, fcInf, fcNegInf}: return -1
      lower[lowerRow * n + row] = value
  for i in 0 ..< n * n:
    if classify(lower[i]) in {fcNan, fcInf, fcNegInf} or classify(upper[i]) in {fcNan, fcInf, fcNegInf}: return -1
  let outputLength = 2 * n * n
  if output == nil or capacity < csize_t(outputLength): return -2
  for i in 0 ..< n * n: output[i] = lower[i]
  for i in 0 ..< n * n: output[n * n + i] = upper[i]
  int64(outputLength)
