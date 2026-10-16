import std/math

const MaxDimension = 6
const MaxEntryMicro = 1_000_000_000'i64

proc writeF64Le(output: ptr UncheckedArray[uint8], offset: int, value: float64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc cholesky_decomposition*(values: ptr UncheckedArray[int64], length: csize_t,
                             output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cholesky_decomposition".} =
  if values.isNil or length < 1 or values[0] < 1 or values[0] > MaxDimension: return -1
  let n = int(values[0])
  if length != csize_t(1 + n * n): return -1

  var matrix: array[MaxDimension * MaxDimension, float64]
  var lower: array[MaxDimension * MaxDimension, float64]
  for index in 0 ..< n * n:
    let scaled = values[index + 1]
    if scaled < -MaxEntryMicro or scaled > MaxEntryMicro: return -1
    matrix[index] = float64(scaled) / 1_000_000.0
  for row in 0 ..< n:
    for column in 0 ..< n:
      let left = matrix[row * n + column]
      let right = matrix[column * n + row]
      if abs(left - right) > 1.0e-8 + 1.0e-5 * abs(right): return -1

  for row in 0 ..< n:
    for column in 0 .. row:
      var sum = 0.0
      for index in 0 ..< column:
        sum += lower[row * n + index] * lower[column * n + index]
      let residual = matrix[row * n + column] - sum
      if row == column:
        if residual <= 0.0: return -1
        lower[row * n + column] = sqrt(residual)
      else:
        lower[row * n + column] = residual / lower[column * n + column]

  let outputBytes = n * n * 8
  if csize_t(outputBytes) > outputCapacity or output.isNil: return -2
  for index in 0 ..< n * n:
    writeF64Le(output, index * 8, lower[index])
  int64(outputBytes)
