const MaxN = 8
const MaxEdges = 28
const MaxInput = 87
const MaxOutput = 80
const Prime = 65_521'i64

proc norm(value: int64): int64 =
  let remainder = value mod Prime
  if remainder < 0: remainder + Prime else: remainder

proc modPow(base: int64, exponentValue: uint64): int64 =
  var exponent = exponentValue
  var result = 1'i64
  var factor = norm(base)
  while exponent != 0:
    if (exponent and 1'u64) != 0: result = (result * factor) mod Prime
    factor = (factor * factor) mod Prime
    exponent = exponent shr 1
  result

proc storeWord(bytes: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    bytes[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc eliminate(inverse: var array[MaxN * MaxN, int64],
    rows: var array[MaxN, bool], columns: var array[MaxN, bool],
    n, pivotRow, pivotColumn: int): bool =
  let old = inverse
  let pivot = old[pivotRow * MaxN + pivotColumn]
  if pivot == 0: return false
  let inversePivot = modPow(pivot, uint64(Prime - 2))
  for row in 0 ..< n:
    for column in 0 ..< n:
      let index = row * MaxN + column
      if rows[row] and row != pivotRow and columns[column] and column != pivotColumn:
        let correction = (old[row * MaxN + pivotColumn] * old[pivotRow * MaxN + column]) mod Prime
        inverse[index] = norm(old[index] - correction * inversePivot)
      else:
        inverse[index] = 0
  rows[pivotRow] = false
  columns[pivotColumn] = false
  true

proc tutte_matrix_randomized_perfect_matching*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tutte_matrix_randomized_perfect_matching".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  let edgeCountValue = input[1]
  if nValue < 2 or nValue > MaxN or (nValue and 1) != 0 or
      edgeCountValue < 0 or edgeCountValue > MaxEdges: return -1
  let n, edgeCount = int(nValue), int(edgeCountValue)
  if edgeCount > n * (n - 1) div 2 or int(length) != 2 + 3 * edgeCount: return -1

  var matrix: array[MaxN * MaxN, int64]
  var previousU = -1'i64
  var previousV = -1'i64
  for edge in 0 ..< edgeCount:
    let uValue = input[2 + 3 * edge]
    let vValue = input[3 + 3 * edge]
    let substitution = input[4 + 3 * edge]
    if uValue < 0 or vValue <= uValue or vValue >= nValue or
        uValue < previousU or (uValue == previousU and vValue <= previousV) or
        substitution < 1 or substitution >= Prime: return -1
    let u, v = int(uValue), int(vValue)
    matrix[u * MaxN + v] = substitution
    matrix[v * MaxN + u] = Prime - substitution
    previousU = uValue
    previousV = vValue

  var augmented: array[MaxN * (2 * MaxN), int64]
  for row in 0 ..< n:
    for column in 0 ..< n:
      augmented[row * (2 * MaxN) + column] = matrix[row * MaxN + column]
    augmented[row * (2 * MaxN) + n + row] = 1
  var singular = false
  for column in 0 ..< n:
    var pivotRow = column
    while pivotRow < n and augmented[pivotRow * (2 * MaxN) + column] == 0: inc pivotRow
    if pivotRow == n:
      singular = true
      break
    if pivotRow != column:
      for j in 0 ..< 2 * n:
        swap(augmented[column * (2 * MaxN) + j], augmented[pivotRow * (2 * MaxN) + j])
    let inversePivot = modPow(augmented[column * (2 * MaxN) + column], uint64(Prime - 2))
    for j in 0 ..< 2 * n:
      augmented[column * (2 * MaxN) + j] =
        (augmented[column * (2 * MaxN) + j] * inversePivot) mod Prime
    for row in 0 ..< n:
      if row == column: continue
      let factor = augmented[row * (2 * MaxN) + column]
      if factor == 0: continue
      for j in 0 ..< 2 * n:
        augmented[row * (2 * MaxN) + j] = norm(
          augmented[row * (2 * MaxN) + j] - factor * augmented[column * (2 * MaxN) + j])

  var result: array[2 + MaxN, int64]
  var resultSize = 2
  if not singular:
    var inverse: array[MaxN * MaxN, int64]
    for row in 0 ..< n:
      for column in 0 ..< n:
        inverse[row * MaxN + column] = augmented[row * (2 * MaxN) + n + column]
    var rows, columns: array[MaxN, bool]
    for i in 0 ..< n:
      rows[i] = true
      columns[i] = true
    var failed = false
    for vertex in 0 ..< n:
      if not columns[vertex]: continue
      var partner = -1
      for candidate in 0 ..< n:
        if rows[candidate] and candidate != vertex and
            matrix[vertex * MaxN + candidate] != 0 and
            inverse[candidate * MaxN + vertex] != 0:
          partner = candidate
          break
      if partner < 0 or resultSize + 2 > result.len:
        failed = true
        break
      result[resultSize] = int64(vertex)
      result[resultSize + 1] = int64(partner)
      resultSize += 2
      if not eliminate(inverse, rows, columns, n, partner, vertex) or
          not eliminate(inverse, rows, columns, n, vertex, partner):
        failed = true
        break
    if failed: resultSize = 2
    else:
      result[0] = 1
      result[1] = int64(n div 2)

  let outputBytes = resultSize * 8
  if output.isNil or int(capacity) < outputBytes: return -2
  var staged: array[MaxOutput, uint8]
  for word in 0 ..< resultSize: storeWord(addr staged[0], word, result[word])
  for byte in 0 ..< outputBytes: output[byte] = staged[byte]
  int64(outputBytes)
