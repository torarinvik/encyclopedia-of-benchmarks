const
  Modulus = 998244353'i64
  MaxOrder = 8
  MaxTerms = 2 * MaxOrder
  MaxInputValues = 1 + MaxTerms + 1

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

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc inferRecurrence(sequence: array[MaxTerms, int64], termCount: int,
    coefficients: var array[MaxTerms + 1, int64]): int =
  var current: array[MaxTerms + 1, int64]
  var previous: array[MaxTerms + 1, int64]
  var old: array[MaxTerms + 1, int64]
  var currentLength = 0
  var previousLength = 0
  var lastIndex = -1
  var lastDiscrepancy = 0'i64

  for index in 0 ..< termCount:
    var predicted = 0'i64
    for lag in 0 ..< min(currentLength, index):
      predicted = normalize(predicted + multiply(sequence[index - lag - 1], current[lag]))
    let discrepancy = normalize(sequence[index] - predicted)
    if discrepancy == 0: continue

    if lastIndex < 0:
      lastIndex = index
      lastDiscrepancy = discrepancy
      currentLength = index + 1
      for lag in 0 ..< currentLength: current[lag] = 0
      continue

    for lag in 0 ..< currentLength: old[lag] = current[lag]
    let oldLength = currentLength
    let shift = index - lastIndex
    let scale = multiply(discrepancy, power(lastDiscrepancy, Modulus - 2))
    let neededLength = previousLength + shift
    if currentLength < neededLength:
      for lag in currentLength ..< neededLength: current[lag] = 0
      currentLength = neededLength
    current[shift - 1] = normalize(current[shift - 1] + scale)
    for lag in 0 ..< previousLength:
      current[shift + lag] = normalize(current[shift + lag] - multiply(scale, previous[lag]))

    if oldLength - index < previousLength - lastIndex:
      for lag in 0 ..< oldLength: previous[lag] = old[lag]
      previousLength = oldLength
      lastIndex = index
      lastDiscrepancy = discrepancy

  for lag in 0 ..< currentLength: coefficients[lag] = current[lag]
  currentLength

proc berlekamp_massey*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "berlekamp_massey".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputValues): return -1
  let boundValue = input[0]
  if boundValue < 1 or boundValue > int64(MaxOrder): return -1
  let bound = int(boundValue)
  let termCount = 2 * bound
  if length != csize_t(1 + termCount): return -1

  var sequence: array[MaxTerms, int64]
  for index in 0 ..< termCount:
    let value = input[1 + index]
    if value < 0 or value >= Modulus: return -1
    sequence[index] = value
  var coefficients: array[MaxTerms + 1, int64]
  let order = inferRecurrence(sequence, termCount, coefficients)
  if order > bound: return -1

  let outputBytes = 8 * (order + 1)
  if output.isNil or capacity < csize_t(outputBytes): return -2
  storeI64Le(output, 0, int64(order))
  for lag in 0 ..< order:
    storeI64Le(output, 8 * (lag + 1), coefficients[lag])
  int64(outputBytes)
