const MaxN = 7
const MaxInputWords = 52

proc residue(value, modulus: int64): int64 =
  let remainder = value mod modulus
  if remainder < 0: remainder + modulus else: remainder

proc negativeResidue(value, modulus: int64): int64 =
  if value == 0: 0 else: modulus - value

proc storeI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[word * 8 + byte] = uint8((bits shr (8 * byte)) and 255)

proc berkowitz_characteristic_polynomial*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64
    {.cdecl, exportc: "berkowitz_characteristic_polynomial".} =
  if input.isNil or length < 3 or length > MaxInputWords:
    return -1
  let n64 = input[0]
  let modulus = input[1]
  if n64 < 1 or n64 > int64(MaxN) or modulus < 2 or modulus > 1_000_000_000:
    return -1
  let n = int(n64)
  if length != csize_t(2 + n * n):
    return -1

  var matrix: array[MaxN * MaxN, int64]
  for i in 0 ..< n * n:
    let entry = input[i + 2]
    if entry < -1_000_000'i64 or entry > 1_000_000'i64:
      return -1
    matrix[i] = residue(entry, modulus)
  let outputBytes = (n + 1) * 8
  if output.isNil or outputCapacity < csize_t(outputBytes):
    return -2

  var coefficients: array[MaxN + 1, int64]
  var current: array[MaxN + 1, int64]
  var toeplitz: array[MaxN + 1, int64]
  var vector: array[MaxN, int64]
  var nextVector: array[MaxN, int64]
  coefficients[0] = 1
  for size in 1 .. n:
    let start = n - size
    let block = size - 1
    for i in 0 .. size:
      toeplitz[i] = 0
    toeplitz[0] = 1
    toeplitz[1] = negativeResidue(matrix[start * n + start], modulus)
    for row in 0 ..< block:
      vector[row] = matrix[(start + 1 + row) * n + start]
    for power in 0 ..< block:
      var dot = 0'i64
      for col in 0 ..< block:
        dot = (dot + matrix[start * n + start + 1 + col] * vector[col]) mod modulus
      toeplitz[power + 2] = negativeResidue(dot, modulus)
      for row in 0 ..< block:
        var value = 0'i64
        for col in 0 ..< block:
          value = (value + matrix[(start + 1 + row) * n + start + 1 + col]
            * vector[col]) mod modulus
        nextVector[row] = value
      for row in 0 ..< block:
        vector[row] = nextVector[row]
    for i in 0 .. size:
      var value = 0'i64
      let lastChild = min(i, size - 1)
      for j in 0 .. lastChild:
        value = (value + toeplitz[i - j] * coefficients[j]) mod modulus
      current[i] = value
    for i in 0 .. size:
      coefficients[i] = current[i]
  for i in 0 .. n:
    storeI64Le(output, i, coefficients[i])
  int64(outputBytes)
