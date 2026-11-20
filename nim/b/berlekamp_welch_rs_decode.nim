const
  Field = 7
  MaxN = 7
  MaxVariables = 8
  MaxPolynomial = 8
  MaxInputLength = 11

proc normalize(value: int): int =
  let remainder = value mod Field
  if remainder < 0: remainder + Field else: remainder

proc trimPolynomial(polynomial: var array[MaxPolynomial, int], length: var int) =
  while length > 1 and polynomial[length - 1] == 0:
    dec length

proc solveHomogeneous(matrix: var array[MaxN, array[MaxVariables, int]],
    rowCount, variableCount: int, solution: var array[MaxVariables, int]): bool =
  var pivotColumns: array[MaxVariables, int]
  var pivotCount = 0
  var pivotRow = 0
  let inverse = [0, 1, 4, 5, 2, 3, 6]

  for column in 0 ..< variableCount:
    var found = -1
    for row in pivotRow ..< rowCount:
      if matrix[row][column] != 0:
        found = row
        break
    if found < 0: continue
    swap(matrix[pivotRow], matrix[found])

    let scale = inverse[matrix[pivotRow][column]]
    for c in 0 ..< variableCount:
      matrix[pivotRow][c] = normalize(matrix[pivotRow][c] * scale)
    for row in 0 ..< rowCount:
      if row == pivotRow: continue
      let factor = matrix[row][column]
      if factor == 0: continue
      for c in 0 ..< variableCount:
        matrix[row][c] = normalize(matrix[row][c] - factor * matrix[pivotRow][c])

    pivotColumns[pivotCount] = column
    inc pivotCount
    inc pivotRow
    if pivotRow == rowCount: break

  var freeColumn = -1
  for column in 0 ..< variableCount:
    var isPivot = false
    for index in 0 ..< pivotCount:
      if pivotColumns[index] == column:
        isPivot = true
        break
    if not isPivot:
      freeColumn = column
      break
  if freeColumn < 0: return false

  for column in 0 ..< MaxVariables: solution[column] = 0
  solution[freeColumn] = 1
  for row in 0 ..< pivotCount:
    solution[pivotColumns[row]] = normalize(-matrix[row][freeColumn])
  true

proc dividePolynomials(numerator, denominator: array[MaxPolynomial, int],
    numeratorLength, denominatorLength: int,
    quotient: var array[MaxPolynomial, int], quotientLength: var int): bool =
  var remainder = numerator
  var remainderLength = numeratorLength
  var divisor = denominator
  var divisorLength = denominatorLength
  trimPolynomial(remainder, remainderLength)
  trimPolynomial(divisor, divisorLength)
  if divisorLength == 1 and divisor[0] == 0: return false

  for index in 0 ..< MaxPolynomial: quotient[index] = 0
  quotientLength = max(1, remainderLength - divisorLength + 1)
  let inverse = [0, 1, 4, 5, 2, 3, 6]
  let inverseLead = inverse[divisor[divisorLength - 1]]
  while not (remainderLength == 1 and remainder[0] == 0) and remainderLength >= divisorLength:
    let shift = remainderLength - divisorLength
    let factor = normalize(remainder[remainderLength - 1] * inverseLead)
    quotient[shift] = factor
    for index in 0 ..< divisorLength:
      remainder[shift + index] = normalize(remainder[shift + index] - factor * divisor[index])
    trimPolynomial(remainder, remainderLength)
  if remainderLength != 1 or remainder[0] != 0: return false
  trimPolynomial(quotient, quotientLength)
  true

proc decode(n, k, errorLimit: int, received: array[MaxN, int]): int64 =
  let qCount = k + errorLimit
  let eCount = errorLimit + 1
  let variableCount = qCount + eCount
  var matrix: array[MaxN, array[MaxVariables, int]]
  for row in 0 ..< n:
    let x = row
    var power = 1
    for degree in 0 ..< qCount:
      matrix[row][degree] = power
      power = (power * x) mod Field
    power = 1
    for degree in 0 ..< eCount:
      matrix[row][qCount + degree] = normalize(-received[row] * power)
      power = (power * x) mod Field

  var solution: array[MaxVariables, int]
  if not solveHomogeneous(matrix, n, variableCount, solution): return 0
  var numerator: array[MaxPolynomial, int]
  var locator: array[MaxPolynomial, int]
  for degree in 0 ..< qCount: numerator[degree] = solution[degree]
  for degree in 0 ..< eCount: locator[degree] = solution[qCount + degree]
  var numeratorLength = qCount
  var locatorLength = eCount
  trimPolynomial(numerator, numeratorLength)
  trimPolynomial(locator, locatorLength)

  var coefficients: array[MaxPolynomial, int]
  var coefficientLength = 0
  if not dividePolynomials(numerator, locator, numeratorLength, locatorLength,
      coefficients, coefficientLength): return 0
  if coefficientLength > k: return 0

  var mismatches = 0
  for x in 0 ..< n:
    var value = 0
    for degree in countdown(k - 1, 0):
      value = (value * x + (if degree < coefficientLength: coefficients[degree] else: 0)) mod Field
    if value != received[x]: inc mismatches
  if mismatches > errorLimit: return 0

  var encoded = 1'i64
  var place = 1'i64
  for degree in 0 ..< k:
    if degree < coefficientLength: encoded += int64(coefficients[degree]) * place
    place *= Field
  encoded

proc berlekamp_welch_rs_decode*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "berlekamp_welch_rs_decode".} =
  if input.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  let nValue = input[0]
  let kValue = input[1]
  let errorValue = input[2]
  if nValue < 2 or nValue > MaxN or kValue < 1 or kValue > 3
      or kValue > nValue or errorValue < 0 or errorValue > 2: return -1
  let n, k, errorLimit = int(nValue), int(kValue), int(errorValue)
  if 2 * errorLimit > n - k or length != csize_t(3 + n): return -1

  var received: array[MaxN, int]
  for index in 0 ..< n:
    let symbol = input[3 + index]
    if symbol < 0 or symbol >= Field: return -1
    received[index] = int(symbol)
  decode(n, k, errorLimit, received)
