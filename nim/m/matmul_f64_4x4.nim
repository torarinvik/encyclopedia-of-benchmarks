const MaxIterations = 10_000'i64
const MatrixElements = 16
const A: array[16, float64] = [4.5, 1.3, 6.0, 4.1, 2.5, 7.2, 7.7, 1.7,
  6.7, 1.3, 9.4, 1.3, 1.1, 2.2, 3.0, 2.1]
const B: array[16, float64] = [1.0, 7.9, 5.1, 3.4, 6.6, 2.8, 5.4, 9.2,
  5.0, 4.1, 4.1, 9.9, 8.4, 3.7, 9.5, 6.4]

proc matmul_f64_4x4*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "matmul_f64_4x4".} =
  if input.isNil or inputLength != csize_t(1): return -1
  let requested = input[0]
  if requested != requested or requested < 1.0 or requested > float64(MaxIterations): return -1
  if float64(int64(requested)) != requested: return -1
  let iterations = int64(requested)

  var staged: array[MatrixElements, float64]
  for _ in 0 ..< int(iterations):
    for row in 0 ..< 4:
      for column in 0 ..< 4:
        var sum = A[row * 4] * B[column]
        sum += A[row * 4 + 1] * B[4 + column]
        sum += A[row * 4 + 2] * B[8 + column]
        sum += A[row * 4 + 3] * B[12 + column]
        staged[row * 4 + column] = sum

  if output.isNil or outputCapacity < csize_t(MatrixElements): return -2
  for index in 0 ..< MatrixElements: output[index] = staged[index]
  int64(MatrixElements)
