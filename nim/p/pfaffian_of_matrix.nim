type InputWords = ptr UncheckedArray[int64]

const
  Modulus = 998244353'i64
  MaxN = 8
  MaxDimension = 16
  MaxParseable = 258

proc normalize(value: int64): int64 =
  let remainder = value mod Modulus
  if remainder < 0: remainder + Modulus else: remainder

proc multiply(left, right: int64): int64 = (left * right) mod Modulus

proc power(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = multiply(result, base)
    base = multiply(base, base)
    exponent = exponent shr 1
  result

proc pfaffian_of_matrix*(input: InputWords, length: csize_t): int64
    {.cdecl, exportc: "pfaffian_of_matrix".} =
  if input == nil or length < csize_t(5) or length > csize_t(MaxParseable): return -1
  let half = input[0]
  if half < 1 or half > int64(MaxN): return -1
  let dimension = 2 * int(half)
  if length != csize_t(1 + dimension * dimension): return -1

  var matrix: array[MaxDimension * MaxDimension, int64]
  for row in 0 ..< dimension:
    for column in 0 ..< dimension:
      let value = input[1 + row * dimension + column]
      if value < 0 or value >= Modulus: return -1
      matrix[row * MaxDimension + column] = value
  for row in 0 ..< dimension:
    if matrix[row * MaxDimension + row] != 0: return -1
    for column in row + 1 ..< dimension:
      if (matrix[row * MaxDimension + column]
          + matrix[column * MaxDimension + row]) mod Modulus != 0:
        return -1

  var result = 1'i64
  for pivotIndex in countup(0, dimension - 1, 2):
    var partner = pivotIndex + 1
    while partner < dimension and matrix[pivotIndex * MaxDimension + partner] == 0:
      inc partner
    if partner == dimension: return 0
    if partner != pivotIndex + 1:
      let swapped = pivotIndex + 1
      for k in 0 ..< dimension:
        swap(matrix[swapped * MaxDimension + k], matrix[partner * MaxDimension + k])
      for k in 0 ..< dimension:
        swap(matrix[k * MaxDimension + swapped], matrix[k * MaxDimension + partner])
      result = if result == 0: 0 else: Modulus - result

    let first = pivotIndex * MaxDimension
    let second = (pivotIndex + 1) * MaxDimension
    let pivot = matrix[first + pivotIndex + 1]
    result = multiply(result, pivot)
    let inverse = power(pivot, Modulus - 2)
    for row in pivotIndex + 2 ..< dimension:
      for column in row + 1 ..< dimension:
        let cross = normalize(multiply(matrix[first + row], matrix[second + column])
          - multiply(matrix[first + column], matrix[second + row]))
        let value = normalize(matrix[row * MaxDimension + column] - multiply(cross, inverse))
        matrix[row * MaxDimension + column] = value
        matrix[column * MaxDimension + row] = if value == 0: 0 else: Modulus - value
  result
