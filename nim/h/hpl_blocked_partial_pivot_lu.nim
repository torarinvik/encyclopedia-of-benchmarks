import std/math

const MaxN = 8
const MaxInput = 66
const MaxOutput = 72

proc hplBlockedPartialPivotLu*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "hpl_blocked_partial_pivot_lu".} =
  if input.isNil or length < csize_t(1) or length > csize_t(MaxInput): return -1
  let rawN = input[0]
  if not rawN.isFinite or rawN != floor(rawN) or rawN < 2 or rawN > float64(MaxN): return -1
  let n = int(rawN)
  if int(length) != 1 + n*n: return -1
  var a: array[MaxN*MaxN, float64]
  for i in 0 ..< n*n:
    let x = input[i+1]
    if not x.isFinite or x != floor(x) or x < -16 or x > 16: return -1
    a[i] = x
  var pivots: array[MaxN, int]
  var panel = 0
  while panel < n:
    let panelEnd = min(panel + 2, n)
    for col in panel ..< panelEnd:
      var pivotRow = col
      var pivotMagnitude = abs(a[col*n+col])
      for row in col+1 ..< n:
        let magnitude = abs(a[row*n+col])
        if magnitude > pivotMagnitude:
          pivotMagnitude = magnitude
          pivotRow = row
      if not pivotMagnitude.isFinite or pivotMagnitude == 0: return -1
      pivots[col] = pivotRow
      if pivotRow != col:
        for j in 0 ..< n:
          swap(a[col*n+j], a[pivotRow*n+j])
      let diagonal = a[col*n+col]
      if not diagonal.isFinite or diagonal == 0: return -1
      for row in col+1 ..< n:
        a[row*n+col] /= diagonal
        if not a[row*n+col].isFinite: return -1
        let multiplier = a[row*n+col]
        for j in col+1 ..< panelEnd:
          a[row*n+j] -= multiplier * a[col*n+j]
          if not a[row*n+j].isFinite: return -1
    for row in panel ..< panelEnd:
      for col in panelEnd ..< n:
        var value = a[row*n+col]
        for inner in panel ..< row:
          value -= a[row*n+inner] * a[inner*n+col]
        if not value.isFinite: return -1
        a[row*n+col] = value
    for row in panelEnd ..< n:
      for col in panelEnd ..< n:
        var update = 0.0
        for inner in panel ..< panelEnd:
          update += a[row*n+inner] * a[inner*n+col]
        a[row*n+col] -= update
        if not a[row*n+col].isFinite: return -1
    panel = panelEnd
  var staged: array[MaxOutput, float64]
  for i in 0 ..< n: staged[i] = float64(pivots[i])
  for i in 0 ..< n*n:
    if not a[i].isFinite: return -1
    staged[n+i] = a[i]
  let outputLength = n+n*n
  if output.isNil or capacity < csize_t(outputLength): return -2
  for i in 0 ..< outputLength: output[i] = staged[i]
  int64(outputLength)
