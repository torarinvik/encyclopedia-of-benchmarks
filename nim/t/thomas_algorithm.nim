const MaxN = 32

proc putF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc thomas_algorithm*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "thomas_algorithm".} =
  if input.isNil or length < 5 or length > csize_t(1 + 4 * MaxN): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > int64(MaxN): return -1
  let n = int(nValue)
  if length != csize_t(1 + 4 * n): return -1

  var lower, diagonal, upper, rhs: array[MaxN, int64]
  for row in 0 ..< n:
    lower[row] = input[1 + row]
    diagonal[row] = input[1 + n + row]
    upper[row] = input[1 + 2 * n + row]
    rhs[row] = input[1 + 3 * n + row]
  if lower[0] != 0 or upper[n - 1] != 0: return -1
  for row in 0 ..< n:
    if lower[row] < -16 or lower[row] > 16 or upper[row] < -16 or upper[row] > 16: return -1
    if diagonal[row] < 17 or diagonal[row] > 64 or rhs[row] < -1000 or rhs[row] > 1000: return -1
    let lowerAbs = if lower[row] < 0: -lower[row] else: lower[row]
    let upperAbs = if upper[row] < 0: -upper[row] else: upper[row]
    if diagonal[row] <= lowerAbs + upperAbs: return -1
  let outputBytes = n * 8
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var modifiedUpper, modifiedRhs, solution: array[MaxN, float64]
  modifiedUpper[0] = float64(upper[0]) / float64(diagonal[0])
  modifiedRhs[0] = float64(rhs[0]) / float64(diagonal[0])
  for row in 1 ..< n:
    let pivot = float64(diagonal[row]) - float64(lower[row]) * modifiedUpper[row - 1]
    if row + 1 < n: modifiedUpper[row] = float64(upper[row]) / pivot
    modifiedRhs[row] = (float64(rhs[row]) - float64(lower[row]) * modifiedRhs[row - 1]) / pivot
  solution[n - 1] = modifiedRhs[n - 1]
  if n > 1:
    for row in countdown(n - 2, 0):
      solution[row] = modifiedRhs[row] - modifiedUpper[row] * solution[row + 1]
  for row in 0 ..< n: putF64Le(output, row * 8, solution[row])
  int64(outputBytes)
