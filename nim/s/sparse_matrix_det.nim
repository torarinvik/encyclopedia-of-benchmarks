const
  Modulus = 998244353'i64
  MaxN = 8
  MaxK = 64
  MaxParseableInput = 195
  Attempts = 4

proc addMod(a, b: int64): int64 =
  let value = a + b
  if value >= Modulus: value - Modulus else: value

proc subMod(a, b: int64): int64 =
  let value = a - b
  if value < 0: value + Modulus else: value

proc mulMod(a, b: int64): int64 = (a * b) mod Modulus

proc powMod(valueValue, exponentValue: int64): int64 =
  var value = valueValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = mulMod(result, value)
    value = mulMod(value, value)
    exponent = exponent shr 1
  result

proc nextResidue(state: var int64): int64 =
  state = (state * 48271 + 1) mod Modulus
  state

proc berlekampMassey(sequence: array[2 * MaxN, int64], length: int,
    connection: var array[MaxN + 1, int64]): int =
  var previous: array[MaxN + 1, int64]
  var temporary: array[MaxN + 1, int64]
  connection = default(array[MaxN + 1, int64])
  connection[0] = 1
  previous[0] = 1
  var degree = 0
  var shift = 1
  var previousDegree = 0
  var lastDiscrepancy = 1'i64
  for index in 0 ..< length:
    var discrepancy = sequence[index]
    for i in 1 .. degree:
      discrepancy = addMod(discrepancy, mulMod(connection[i], sequence[index - i]))
    if discrepancy == 0:
      inc shift
      continue
    temporary = connection
    let scale = mulMod(discrepancy, powMod(lastDiscrepancy, Modulus - 2))
    for i in 0 .. previousDegree:
      let target = i + shift
      if target <= MaxN: connection[target] = subMod(connection[target], mulMod(scale, previous[i]))
    if 2 * degree <= index:
      let oldDegree = degree
      degree = index + 1 - degree
      previous = temporary
      previousDegree = oldDegree
      lastDiscrepancy = discrepancy
      shift = 1
    else:
      inc shift
  degree

proc denseDeterminant(row, column: array[MaxK, int], entry: array[MaxK, int64],
    n, k: int): int64 =
  var matrix: array[MaxN, array[MaxN, int64]]
  for e in 0 ..< k: matrix[row[e]][column[e]] = entry[e]
  result = 1
  for c in 0 ..< n:
    var pivot = c
    while pivot < n and matrix[pivot][c] == 0: inc pivot
    if pivot == n: return 0
    if pivot != c:
      swap(matrix[pivot], matrix[c])
      result = Modulus - result
    let pivotValue = matrix[c][c]
    result = mulMod(result, pivotValue)
    let inverse = powMod(pivotValue, Modulus - 2)
    for i in c + 1 ..< n:
      if matrix[i][c] == 0: continue
      let factor = mulMod(matrix[i][c], inverse)
      for j in c + 1 ..< n: matrix[i][j] = subMod(matrix[i][j], mulMod(factor, matrix[c][j]))
      matrix[i][c] = 0

proc sparseWiedemann(row, column: array[MaxK, int], entry: array[MaxK, int64],
    n, k: int, seedValue: int64): tuple[success: bool, determinant: int64] =
  var state = seedValue
  var diagonal, left, vector, next, weighted: array[MaxN, int64]
  var sequence: array[2 * MaxN, int64]
  var diagonalProduct = 1'i64
  for i in 0 ..< n:
    diagonal[i] = nextResidue(state)
    if diagonal[i] == 0: diagonal[i] = 1
    left[i] = nextResidue(state)
    vector[i] = nextResidue(state)
    diagonalProduct = mulMod(diagonalProduct, diagonal[i])
  for step in 0 ..< 2 * n:
    var dot = 0'i64
    for i in 0 ..< n: dot = addMod(dot, mulMod(left[i], vector[i]))
    sequence[step] = dot
    for i in 0 ..< n: weighted[i] = mulMod(diagonal[i], vector[i])
    next = default(array[MaxN, int64])
    for e in 0 ..< k:
      next[row[e]] = addMod(next[row[e]], mulMod(entry[e], weighted[column[e]]))
    vector = next
  var connection: array[MaxN + 1, int64]
  let degree = berlekampMassey(sequence, 2 * n, connection)
  if degree != n: return (false, 0'i64)
  var constant = connection[n]
  if (n and 1) != 0 and constant != 0: constant = Modulus - constant
  (true, mulMod(constant, powMod(diagonalProduct, Modulus - 2)))

proc storeI64Le(output: ptr UncheckedArray[uint8], value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[byte] = uint8((bits shr (8 * byte)) and 255)

proc sparse_matrix_det*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sparse_matrix_det".} =
  if input.isNil or length < 2 or length > csize_t(MaxParseableInput): return -1
  let nValue = input[0]
  let kValue = input[1]
  if nValue < 1 or nValue > int64(MaxN) or kValue < 1 or kValue > int64(MaxK): return -1
  let n = int(nValue)
  let k = int(kValue)
  if length != csize_t(2 + 3 * k): return -1
  var seen: array[MaxN, array[MaxN, bool]]
  var row, column: array[MaxK, int]
  var entry: array[MaxK, int64]
  for e in 0 ..< k:
    let r = input[2 + 3 * e]
    let c = input[3 + 3 * e]
    let value = input[4 + 3 * e]
    if r < 0 or r >= n.int64 or c < 0 or c >= n.int64 or value < 1 or value >= Modulus: return -1
    if seen[int(r)][int(c)]: return -1
    seen[int(r)][int(c)] = true
    row[e] = int(r)
    column[e] = int(c)
    entry[e] = value
  var determinant = 0'i64
  var found = false
  for attempt in 0 ..< Attempts:
    var seed = 104729'i64 + int64(attempt) * 1000003'i64
    if seed >= Modulus: seed = seed mod Modulus
    let candidate = sparseWiedemann(row, column, entry, n, k, seed)
    if candidate.success:
      determinant = candidate.determinant
      found = true
      break
  if not found: determinant = denseDeterminant(row, column, entry, n, k)
  if output.isNil or capacity < 8: return -2
  storeI64Le(output, determinant)
  8
