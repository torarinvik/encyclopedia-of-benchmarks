const
  MaxDimension = 8
  MaxInputLength = 65
  InvalidResult = low(int64)

proc bareiss_determinant*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "bareiss_determinant".} =
  if input.isNil or length < 1 or length > MaxInputLength: return InvalidResult
  if input[0] < 1 or input[0] > int64(MaxDimension): return InvalidResult
  let n = int(input[0])
  if int(length) != 1 + n * n: return InvalidResult

  var matrix: array[MaxDimension * MaxDimension, int64]
  for index in 0 ..< n * n:
    let value = input[1 + index]
    if value < -4 or value > 4: return InvalidResult
    matrix[index] = value

  var sign = 1'i64
  var previousPivot = 1'i64
  for k in 0 ..< n - 1:
    if matrix[k * n + k] == 0:
      var replacement = k + 1
      while replacement < n and matrix[replacement * n + k] == 0:
        inc replacement
      if replacement == n: return 0
      for column in 0 ..< n:
        swap(matrix[k * n + column], matrix[replacement * n + column])
      sign = -sign

    let pivot = matrix[k * n + k]
    for row in k + 1 ..< n:
      for column in k + 1 ..< n:
        let numerator = matrix[row * n + column] * pivot -
          matrix[row * n + k] * matrix[k * n + column]
        matrix[row * n + column] = numerator div previousPivot
      matrix[row * n + k] = 0
    previousPivot = pivot

  sign * matrix[(n - 1) * n + n - 1]
