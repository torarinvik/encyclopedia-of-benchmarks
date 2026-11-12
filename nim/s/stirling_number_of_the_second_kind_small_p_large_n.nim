const
  MaxN = 1_000_000_000_000_000_000'i64
  MaxT = 8
  MaxK = 8
  Width = 9

proc isPrime(value: int64): bool =
  if value < 2: return false
  var divisor = 2'i64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc stirlingValue(n: int64, k: int, modulus: int64): int64 =
  var matrix: array[Width * Width, int64]
  var squared: array[Width * Width, int64]
  var vector: array[Width, int64]
  var nextVector: array[Width, int64]
  let dimension = k + 1
  for index in 0 ..< dimension:
    matrix[index * Width + index] = index.int64 mod modulus
    if index > 0: matrix[index * Width + index - 1] = 1
  vector[0] = 1

  var exponent = n
  while exponent > 0:
    if exponent mod 2 != 0:
      for row in 0 ..< dimension:
        var total = 0'i64
        for column in 0 ..< dimension:
          total = (total + matrix[row * Width + column] * vector[column]) mod modulus
        nextVector[row] = total
      for row in 0 ..< dimension: vector[row] = nextVector[row]
    exponent = exponent div 2
    if exponent > 0:
      for row in 0 ..< dimension:
        for column in 0 ..< dimension:
          var total = 0'i64
          for inner in 0 ..< dimension:
            total = (total + matrix[row * Width + inner] * matrix[inner * Width + column]) mod modulus
          squared[row * Width + column] = total
      for row in 0 ..< dimension:
        for column in 0 ..< dimension:
          matrix[row * Width + column] = squared[row * Width + column]
          squared[row * Width + column] = 0
  vector[k]

proc stirling_number_of_the_second_kind_small_p_large_n*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "stirling_number_of_the_second_kind_small_p_large_n".} =
  if input.isNil or length < csize_t(4) or length > csize_t(18): return -1
  let countValue = input[0]
  let modulus = input[1]
  if countValue < 1 or countValue > MaxT.int64: return -1
  if length != csize_t(2 + 2 * countValue): return -1
  if modulus < 11 or modulus > 97 or not isPrime(modulus): return -1

  var result = 0'i64
  for caseIndex in 0 ..< countValue.int:
    let n = input[2 + 2 * caseIndex]
    let kValue = input[3 + 2 * caseIndex]
    if n < 0 or n > MaxN or kValue < 0 or kValue > MaxK.int64 or kValue > n: return -1
    let value = stirlingValue(n, kValue.int, modulus)
    let next = (caseIndex + 1).int64
    result = (result + next * next * value) mod modulus
  result
