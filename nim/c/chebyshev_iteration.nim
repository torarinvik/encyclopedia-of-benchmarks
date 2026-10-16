import std/math

const
  MaxDimension = 8
  MaxMatrixMicro = 1_000_000_000'i64
  MaxVectorMicro = 1_000_000_000'i64
  MaxSpectralMicro = 1_000_000_000'i64
  MaxIterations = 1000'i64

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc chebyshev_iteration*(values: ptr UncheckedArray[int64], length: csize_t,
                         output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
                         {.cdecl, exportc: "chebyshev_iteration".} =
  if values == nil or length < 1 or length > csize_t(1 + MaxDimension * MaxDimension + 2 * MaxDimension + 4): return -1
  if values[0] < 1 or values[0] > MaxDimension: return -1
  let n = int(values[0])
  if length != csize_t(1 + n * n + 2 * n + 4): return -1
  let matrixEnd = 1 + n * n
  let vectorEnd = matrixEnd + 2 * n
  var matrix: array[MaxDimension * MaxDimension, float64]
  var b, x, residual, direction: array[MaxDimension, float64]
  for index in 0 ..< n * n:
    let value = values[1 + index]
    if value < -MaxMatrixMicro or value > MaxMatrixMicro: return -1
    matrix[index] = float64(value) / 1_000_000.0
  for index in 0 ..< n:
    let rhs = values[matrixEnd + index]
    let guess = values[matrixEnd + n + index]
    if rhs < -MaxVectorMicro or rhs > MaxVectorMicro or guess < -MaxVectorMicro or guess > MaxVectorMicro: return -1
    b[index] = float64(rhs) / 1_000_000.0
    x[index] = float64(guess) / 1_000_000.0
  let minMicro = values[vectorEnd]
  let maxMicro = values[vectorEnd + 1]
  let iterations = values[vectorEnd + 2]
  let toleranceMicro = values[vectorEnd + 3]
  if minMicro < 1 or maxMicro <= minMicro or maxMicro > MaxSpectralMicro or
      iterations < 1 or iterations > MaxIterations or toleranceMicro < 1 or toleranceMicro > MaxVectorMicro: return -1
  let minEigenvalue = float64(minMicro) / 1_000_000.0
  let maxEigenvalue = float64(maxMicro) / 1_000_000.0
  let tolerance = float64(toleranceMicro) / 1_000_000.0
  let outputBytes = n * 8
  if output == nil or outputCapacity < csize_t(outputBytes): return -2

  for row in 0 ..< n:
    var product = 0.0
    for column in 0 ..< n: product += matrix[row * n + column] * x[column]
    residual[row] = b[row] - product
  let d = (maxEigenvalue + minEigenvalue) / 2.0
  let c = (maxEigenvalue - minEigenvalue) / 2.0
  var alpha = 0.0
  var alphaPrevious = 0.0
  for iteration in 0 ..< int(iterations):
    var squares = 0.0
    for index in 0 ..< n: squares += residual[index] * residual[index]
    if sqrt(squares) < tolerance: break
    if iteration == 0:
      alpha = 1.0 / d
      for index in 0 ..< n: direction[index] = residual[index]
    else:
      let halfStep = c * alphaPrevious / 2.0
      let beta = halfStep * halfStep
      alpha = 1.0 / (d - beta / alphaPrevious)
      let directionScale = beta / alphaPrevious
      for index in 0 ..< n: direction[index] = residual[index] + directionScale * direction[index]
    for index in 0 ..< n: x[index] += alpha * direction[index]
    for row in 0 ..< n:
      var product = 0.0
      for column in 0 ..< n: product += matrix[row * n + column] * x[column]
      residual[row] = b[row] - product
    alphaPrevious = alpha

  for index in 0 ..< n: writeF64Le(output, index * 8, x[index])
  int64(outputBytes)
