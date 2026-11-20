const Modulus = 998244353'i64
const MaxStates = 7

proc powMod(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc findState(codes: array[MaxStates, int64], lengths: array[MaxStates, int64],
               count: int, code, length: int64): int =
  for index in 0 ..< count:
    if codes[index] == code and lengths[index] == length: return index
  -1

proc solve(wordLength, first, second: int64): int64 =
  var codes: array[MaxStates, int64]
  var lengths: array[MaxStates, int64]
  var stateCount = 1
  let patterns = [first, second]
  for prefixLength in 1'i64 ..< wordLength:
    for pattern in patterns:
      let code = pattern shr (wordLength - prefixLength)
      if findState(codes, lengths, stateCount, code, prefixLength) < 0:
        codes[stateCount] = code
        lengths[stateCount] = prefixLength
        inc stateCount

  var matrix: array[MaxStates, array[MaxStates + 1, int64]]
  for row in 0 ..< stateCount:
    for column in 0 ..< stateCount:
      matrix[row][column] = if row == column: 2 else: 0
    for bit in 0'i64 .. 1'i64:
      let candidate = (codes[row] shl 1) or bit
      let candidateLength = lengths[row] + 1
      if candidateLength == wordLength and candidate == first:
        inc matrix[row][stateCount]
        continue
      if candidateLength == wordLength and candidate == second: continue

      var suffixLength = candidateLength
      if suffixLength > wordLength - 1: suffixLength = wordLength - 1
      var destination = -1
      while suffixLength >= 0 and destination < 0:
        let suffixMask = (1'i64 shl suffixLength) - 1
        destination = findState(codes, lengths, stateCount,
                                candidate and suffixMask, suffixLength)
        dec suffixLength
      if destination < 0: destination = 0
      matrix[row][destination] = (matrix[row][destination] - 1 + Modulus) mod Modulus

  for column in 0 ..< stateCount:
    var pivot = column
    while pivot < stateCount and matrix[pivot][column] == 0: inc pivot
    if pivot == stateCount: return -1
    if pivot != column: swap(matrix[column], matrix[pivot])
    let inverse = powMod(matrix[column][column], Modulus - 2)
    for index in column .. stateCount:
      matrix[column][index] = matrix[column][index] * inverse mod Modulus
    for row in 0 ..< stateCount:
      if row == column: continue
      let factor = matrix[row][column]
      for index in column .. stateCount:
        let product = factor * matrix[column][index] mod Modulus
        matrix[row][index] = (matrix[row][index] - product + Modulus) mod Modulus
  matrix[0][stateCount]

proc penney_game_pattern_probability*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "penney_game_pattern_probability".} =
  if input.isNil or length != csize_t(3): return -1
  let wordLength = input[0]
  if wordLength < 1 or wordLength > 4: return -1
  let limit = 1'i64 shl wordLength
  let first = input[1]
  let second = input[2]
  if first < 0 or second < 0 or first >= limit or second >= limit or first == second:
    return -1
  solve(wordLength, first, second)
