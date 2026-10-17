import std/math

const MaxInputValues = 11

proc roundedMultiply(left, right: float64): float64 {.noinline.} = left * right
proc roundedSubtract(left, right: float64): float64 {.noinline.} = left - right
proc roundedDivide(left, right: float64): float64 {.noinline.} = left / right

proc validDominance(matrix: array[9, float64], n: int): bool =
  var seen: array[3, bool]
  for row in 0 ..< n:
    var dominant = -1
    for column in 0 ..< n:
      var otherSum = 0.0
      for other in 0 ..< n:
        if other != column: otherSum += abs(matrix[row * n + other])
      if abs(matrix[row * n + column]) > otherSum:
        if dominant >= 0: return false
        dominant = column
    if dominant < 0 or seen[dominant]: return false
    seen[dominant] = true
  true

proc invert(matrix: var array[9, float64], n: int): array[9, float64] =
  var inverse: array[9, float64]
  var identity: array[9, float64]
  var index: array[3, int]
  var scale: array[3, float64]
  for row in 0 ..< n:
    index[row] = row
    identity[row * n + row] = 1.0
    for column in 0 ..< n:
      scale[row] = max(scale[row], abs(matrix[row * n + column]))
  for column in 0 ..< n - 1:
    var bestRatio = 0.0
    var pivotSlot = column
    for slot in column ..< n:
      let row = index[slot]
      let ratio = roundedDivide(abs(matrix[row * n + column]), scale[row])
      if ratio > bestRatio:
        bestRatio = ratio
        pivotSlot = slot
    swap(index[column], index[pivotSlot])
    let pivotRow = index[column]
    for slot in column + 1 ..< n:
      let row = index[slot]
      let ratio = roundedDivide(matrix[row * n + column], matrix[pivotRow * n + column])
      matrix[row * n + column] = ratio
      for trailing in column + 1 ..< n:
        let product = roundedMultiply(ratio, matrix[pivotRow * n + trailing])
        matrix[row * n + trailing] = roundedSubtract(matrix[row * n + trailing], product)
  for pivot in 0 ..< n - 1:
    for rowSlot in pivot + 1 ..< n:
      let row = index[rowSlot]
      let pivotRow = index[pivot]
      for rhs in 0 ..< n:
        let product = roundedMultiply(matrix[row * n + pivot], identity[pivotRow * n + rhs])
        identity[row * n + rhs] = roundedSubtract(identity[row * n + rhs], product)
  for rhs in 0 ..< n:
    let lastRow = index[n - 1]
    inverse[(n - 1) * n + rhs] = roundedDivide(identity[lastRow * n + rhs], matrix[lastRow * n + n - 1])
    for row in countdown(n - 2, 0):
      let sourceRow = index[row]
      var value = identity[sourceRow * n + rhs]
      for column in row + 1 ..< n:
        let product = roundedMultiply(matrix[sourceRow * n + column], inverse[column * n + rhs])
        value = roundedSubtract(value, product)
      inverse[row * n + rhs] = roundedDivide(value, matrix[sourceRow * n + row])
  inverse

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 0xFF'u64)

proc inverse_of_matrix*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "inverse_of_matrix".} =
  if input == nil or length < 1 or length > MaxInputValues.csize_t: return -1
  if input[0] != 2 and input[0] != 3: return -1
  let n = int(input[0])
  if length != csize_t(1 + n * n): return -1
  var matrix: array[9, float64]
  for i in 0 ..< n * n:
    let q = input[i + 1]
    if q < -32 or q > 32: return -1
    matrix[i] = float64(q) / 16.0
  if not validDominance(matrix, n): return -1
  let inverse = invert(matrix, n)
  for i in 0 ..< n * n:
    if classify(inverse[i]) in {fcNan, fcInf, fcNegInf} or abs(inverse[i]) > 32768.0: return -1
  let outputBytes = n * n * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  for i in 0 ..< n * n: putF64Le(output, i * 8, inverse[i])
  int64(outputBytes)
