import std/math

const MaxParseableInputLength = 19
const MaxOrder = 4

proc finite(value: float64): bool = classify(value) notin {fcNan, fcInf, fcNegInf}

proc exactInteger(value: float64, low, high: int): bool =
  finite(value) and value >= float64(low) and value <= float64(high) and float64(int(value)) == value

proc lanczos_symmetric_tridiagonalization*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or inputLength < 3 or inputLength > MaxParseableInputLength.csize_t: return -1
  for index in 0 ..< inputLength.int:
    if not finite(input[index]): return -1
  if not exactInteger(input[0], 1, MaxOrder) or not exactInteger(input[1], 1, MaxOrder): return -1
  let n = int(input[0])
  let k = int(input[1])
  if k > n or inputLength != (2 + n * n).csize_t: return -1
  for row in 0 ..< n:
    for col in 0 ..< n:
      if not exactInteger(input[2 + row * n + col], -4, 4) or
          input[2 + row * n + col] != input[2 + col * n + row]: return -1
  let required = 2 * k
  if output == nil or outputCapacity < required.csize_t: return -2

  var previous: array[4, float64]
  var current: array[4, float64]
  var product: array[4, float64]
  var residual: array[4, float64]
  var next: array[4, float64]
  var diagonal: array[4, float64]
  var offDiagonal: array[3, float64]
  current[0] = 1.0
  var previousBeta = 0.0
  for step in 0 ..< k:
    for row in 0 ..< n:
      product[row] = 0.0
      for col in 0 ..< n: product[row] += input[2 + row * n + col] * current[col]
    var alpha = 0.0
    for index in 0 ..< n: alpha += current[index] * product[index]
    if not finite(alpha): return -3
    diagonal[step] = alpha
    if step + 1 == k: break
    var normSquared = 0.0
    for index in 0 ..< n:
      residual[index] = product[index] - alpha * current[index] - previousBeta * previous[index]
      normSquared += residual[index] * residual[index]
    if not finite(normSquared) or normSquared < 0.0: return -3
    let beta = sqrt(normSquared)
    if not finite(beta) or beta <= 9.094947017729282e-13: return -3
    offDiagonal[step] = beta
    for index in 0 ..< n: next[index] = residual[index] / beta
    for index in 0 ..< n: previous[index] = current[index]
    for index in 0 ..< n: current[index] = next[index]
    previousBeta = beta
  output[0] = float64(k)
  for index in 0 ..< k: output[1 + index] = diagonal[index]
  for index in 0 ..< k - 1: output[1 + k + index] = offDiagonal[index]
  required.int64
