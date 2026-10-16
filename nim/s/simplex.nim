const InvalidResult = -1.0e300
const MaxFinite = 1.7976931348623157e308

proc finiteValue(value: float64): bool =
  value == value and value < MaxFinite and value > -MaxFinite

proc simplex*(input: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "simplex".} =
  if input == nil or length < 4 or length > 132: return InvalidResult
  let nVarsValue = input[0]
  let nArtificialValue = input[1]
  let nRowsValue = input[2]
  let nColsValue = input[3]
  if nVarsValue < 2 or nVarsValue > 4 or nArtificialValue < 0 or nArtificialValue > 2 or
      nRowsValue < 3 or nRowsValue > 8 or nColsValue < nVarsValue + nArtificialValue + 1 or
      nColsValue > 16: return InvalidResult
  var rows = int(nRowsValue)
  var cols = int(nColsValue)
  var artificial = int(nArtificialValue)
  if length != csize_t(4 + rows * cols): return InvalidResult
  var tableau: array[8, array[16, float64]]
  for row in 0 ..< rows:
    for col in 0 ..< cols:
      tableau[row][col] = float64(input[4 + row * cols + col]) / 1_000_000.0
    if tableau[row][cols - 1] < 0.0: return InvalidResult

  var phaseOne = artificial != 0
  var finished = false
  for _ in 0 ..< 100:
    if finished:
      let result = abs(tableau[0][cols - 1])
      return if finiteValue(result): result else: InvalidResult
    let stages = if phaseOne: 2 else: 1
    let sign = if phaseOne: 1.0 else: -1.0
    var pivotCol = 0
    var best = sign * tableau[0][0]
    for col in 1 ..< cols - 1:
      let score = sign * tableau[0][col]
      if score > best:
        best = score
        pivotCol = col
    if best <= 0.0:
      if phaseOne:
        let firstArtificial = cols - artificial - 1
        var compacted: array[8, array[16, float64]]
        for row in 1 ..< rows:
          var newCol = 0
          for col in 0 ..< cols:
            if col >= firstArtificial and col < cols - 1: continue
            compacted[row - 1][newCol] = tableau[row][col]
            inc newCol
        dec rows
        cols -= artificial
        artificial = 0
        tableau = compacted
        phaseOne = false
      else:
        finished = true
      continue

    var found = false
    var pivotRow = 0
    var bestRatio = 0.0
    for row in stages ..< rows:
      let divisor = tableau[row][pivotCol]
      if divisor > 0.0:
        let ratio = tableau[row][cols - 1] / divisor
        if not finiteValue(ratio): return InvalidResult
        if not found or ratio < bestRatio:
          found = true
          bestRatio = ratio
          pivotRow = row
    if not found: return InvalidResult

    let pivot = tableau[pivotRow][pivotCol]
    var normalized: array[16, float64]
    for col in 0 ..< cols: normalized[col] = tableau[pivotRow][col] / pivot
    var columnValues: array[8, float64]
    for row in 0 ..< rows: columnValues[row] = tableau[row][pivotCol]
    for row in 0 ..< rows:
      let coefficient = columnValues[row]
      for col in 0 ..< cols:
        tableau[row][col] += -coefficient * normalized[col]
    for col in 0 ..< cols: tableau[pivotRow][col] = normalized[col]
    for row in 0 ..< rows:
      for col in 0 ..< cols:
        if not finiteValue(tableau[row][col]): return InvalidResult
  InvalidResult
