import std/math

const MinN = 5
const MaxN = 16

proc npb_sp_pentadiagonal_line_solve*(input: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "npb_sp_pentadiagonal_line_solve".} =
  if input.isNil or length < csize_t(31) or length > csize_t(97): return -1
  let nValue = input[0]
  if not nValue.isFinite or nValue != floor(nValue) or nValue < float64(MinN) or nValue > float64(MaxN): return -1
  let n = int(nValue)
  if int(length) != 1 + 6*n: return -1
  if input[1] != 0.0 or input[2] != 0.0 or input[1+n] != 0.0 or
      input[4*n] != 0.0 or input[5*n-1] != 0.0 or input[5*n] != 0.0: return -1
  for row in 0 ..< n:
    let lower2 = input[1+row]
    let lower1 = input[1+n+row]
    let diagonal = input[1+2*n+row]
    let upper1 = input[1+3*n+row]
    let upper2 = input[1+4*n+row]
    let rhs = input[1+5*n+row]
    let bands = [lower2, lower1, upper1, upper2]
    var radius = 0.0
    for band in bands:
      if not band.isFinite or abs(band) > 2.0: return -1
      radius += abs(band)
    if not diagonal.isFinite or diagonal < 5.0 or diagonal > 16.0 or
        not rhs.isFinite or abs(rhs) > 64.0 or diagonal - radius < 0.25: return -1
  if output.isNil or capacity < csize_t(n): return -2
  var lo1, diag, up1, up2, workRhs, solution: array[MaxN, float64]
  for row in 0 ..< n:
    lo1[row] = input[1+n+row]; diag[row] = input[1+2*n+row]
    up1[row] = input[1+3*n+row]; up2[row] = input[1+4*n+row]; workRhs[row] = input[1+5*n+row]
  for pivotRow in 0 ..< n:
    let pivot = diag[pivotRow]
    if pivotRow + 1 < n:
      let row = pivotRow + 1
      let factor = lo1[row] / pivot
      diag[row] -= factor * up1[pivotRow]
      up1[row] -= factor * up2[pivotRow]
      workRhs[row] -= factor * workRhs[pivotRow]
    if pivotRow + 2 < n:
      let row = pivotRow + 2
      let factor = input[1+row] / pivot
      lo1[row] -= factor * up1[pivotRow]
      diag[row] -= factor * up2[pivotRow]
      workRhs[row] -= factor * workRhs[pivotRow]
  for back in countdown(n-1, 0):
    var value = workRhs[back]
    if back + 1 < n: value -= up1[back] * solution[back+1]
    if back + 2 < n: value -= up2[back] * solution[back+2]
    solution[back] = value / diag[back]
  for row in 0 ..< n: output[row] = solution[row]
  int64(n)
