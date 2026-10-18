import math

proc finite(value: float64): bool = classify(value) notin {fcNan, fcInf, fcNegInf}

proc qr_eigen_values*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "qr_eigen_values".} =
  if input == nil or inputLength != 5 or input[0] != 2: return -1
  var matrix: array[4, float64]
  for i in 0 ..< 4:
    let value = input[i + 1]
    if not finite(value) or value < -9 or value > 9 or value != floor(value): return -1
    matrix[i] = value
  if matrix[1] != matrix[2] or matrix[1] == 0 or matrix[0] == matrix[3]: return -1

  var lastEigenvalue = 0.0
  var iterations = 0
  while abs(matrix[2]) > 1e-10:
    if iterations >= 256: return -1
    lastEigenvalue = matrix[3]
    var shifted = matrix
    shifted[0] -= lastEigenvalue
    shifted[3] -= lastEigenvalue
    var q, r: array[4, float64]
    for column in 0 ..< 2:
      var original, residual: array[2, float64]
      for row in 0 ..< 2:
        original[row] = shifted[row * 2 + column]
        residual[row] = original[row]
      for previous in 0 ..< column:
        var basis: array[2, float64]
        for row in 0 ..< 2: basis[row] = q[row * 2 + previous]
        var denominator = 0.0
        for row in 0 ..< 2: denominator += basis[row] * basis[row]
        if denominator == 0 or not finite(denominator): return -1
        var dot = 0.0
        for row in 0 ..< 2: dot += original[row] * basis[row]
        let scalar = dot / denominator
        for row in 0 ..< 2: residual[row] -= scalar * basis[row]
      var normSquared = 0.0
      for row in 0 ..< 2: normSquared += residual[row] * residual[row]
      let norm = sqrt(normSquared)
      if norm == 0 or not finite(norm): return -1
      for row in 0 ..< 2: q[row * 2 + column] = residual[row] / norm
      for target in column ..< 2:
        var dot = 0.0
        for row in 0 ..< 2: dot += q[row * 2 + column] * shifted[row * 2 + target]
        r[column * 2 + target] = dot
    var updated: array[4, float64]
    for row in 0 ..< 2:
      for column in 0 ..< 2:
        for inner in 0 ..< 2:
          updated[row * 2 + column] += r[row * 2 + inner] * q[inner * 2 + column]
    updated[0] += lastEigenvalue
    updated[3] += lastEigenvalue
    for i in 0 ..< 4:
      if not finite(updated[i]): return -1
      matrix[i] = updated[i]
    inc iterations
  let result0 = matrix[0]
  let result1 = lastEigenvalue
  if not finite(result0) or not finite(result1): return -1
  var staged: array[2, float64]
  staged[0] = result0
  staged[1] = result1
  if output == nil or capacity < 2: return -2
  output[0] = staged[0]
  output[1] = staged[1]
  2
