import std/math

proc pseudo_inverse*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64
    {.cdecl, exportc: "pseudo_inverse".} =
  if input == nil or inputLength < 3 or inputLength > 7: return -1
  for i in 0 ..< int(inputLength):
    let value = input[i]
    if classify(value) in {fcNan, fcInf, fcNegInf}: return -1
  if input[0] != floor(input[0]) or input[0] < 1 or input[0] > 4 or
      input[1] != floor(input[1]) or input[1] != 1: return -1
  let rows = int(input[0])
  if inputLength != csize_t(2 + rows): return -1
  var column: array[4, float64]
  var squaredNorm = 0.0
  for i in 0 ..< rows:
    let value = input[2 + i]
    if value != floor(value) or value < -4 or value > 4: return -1
    column[i] = value
    squaredNorm += value * value
  var staged: array[6, float64]
  staged[0] = 1.0
  staged[1] = float64(rows)
  if sqrt(squaredNorm) < 1e-4:
    for i in 0 ..< rows: staged[2 + i] = 0.0
  else:
    for i in 0 ..< rows: staged[2 + i] = column[i] / squaredNorm
  let outputSize = rows + 2
  if output == nil or capacity < csize_t(outputSize): return -2
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
