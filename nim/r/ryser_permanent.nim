const
  MaxDimension = 8
  MaxInputLength = 65
  InvalidResult = low(int64)

proc bitCount(value: int): int =
  var remaining = value
  while remaining != 0:
    result += remaining and 1
    remaining = remaining shr 1

proc ryser_permanent*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ryser_permanent".} =
  if input.isNil or length < 1 or length > MaxInputLength: return InvalidResult
  if input[0] < 1 or input[0] > int64(MaxDimension): return InvalidResult
  let n = int(input[0])
  if int(length) != 1 + n * n: return InvalidResult

  var matrix: array[MaxDimension * MaxDimension, int64]
  for index in 0 ..< n * n:
    let value = input[1 + index]
    if value < -4 or value > 4: return InvalidResult
    matrix[index] = value

  var rowSums: array[MaxDimension, int64]
  var total = 0'i64
  var previousGray = 0
  for ordinal in 0 ..< (1 shl n):
    let gray = ordinal xor (ordinal shr 1)
    if ordinal != 0:
      let changed = gray xor previousGray
      var column = 0
      while ((changed shr column) and 1) == 0: inc column
      let direction = if (gray and changed) != 0: 1'i64 else: -1'i64
      for row in 0 ..< n:
        rowSums[row] += direction * matrix[row * n + column]

    var product = 1'i64
    for row in 0 ..< n:
      product *= rowSums[row]
    if ((n + bitCount(gray)) and 1) != 0: product = -product
    total += product
    previousGray = gray
  total
