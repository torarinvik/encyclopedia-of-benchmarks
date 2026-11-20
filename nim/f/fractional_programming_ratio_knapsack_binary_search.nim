const MaxItems = 12
const MaxWeight = 32
const MaxParseableInputLength = 27
const RatioScale = 1_000_000'i64
const MaxScaledRatio = 1_000_000_000'i64
const NegativeInfinity = -2_305_843_009_213_693_952'i64

proc ratioFeasible(numerators, denominators: array[MaxItems, int64],
                   n, requiredWeight: int, threshold: int64): bool =
  var current: array[MaxWeight + 1, int64]
  var next: array[MaxWeight + 1, int64]
  for weight in 0 .. requiredWeight:
    current[weight] = NegativeInfinity
  current[0] = 0
  for item in 0 ..< n:
    for weight in 0 .. requiredWeight:
      next[weight] = current[weight]
    let score = RatioScale * numerators[item] - threshold * denominators[item]
    for weight in 0 .. requiredWeight:
      if current[weight] != NegativeInfinity:
        let sumWeight = weight + int(denominators[item])
        let target = if sumWeight < requiredWeight: sumWeight else: requiredWeight
        let candidate = current[weight] + score
        if candidate > next[target]: next[target] = candidate
    current = next
  current[requiredWeight] >= 0

proc fractional_programming_ratio_knapsack_binary_search*(input: ptr UncheckedArray[int64],
                                                             length: csize_t): int64
    {.cdecl, exportc: "fractional_programming_ratio_knapsack_binary_search".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return -1
  let nValue = input[0]
  let requiredValue = input[1]
  if nValue < 1 or nValue > MaxItems or requiredValue < 1 or requiredValue > MaxWeight:
    return -1
  let n = int(nValue)
  let requiredWeight = int(requiredValue)
  if length != csize_t(2 + 2 * n): return -1

  var numerators: array[MaxItems, int64]
  var denominators: array[MaxItems, int64]
  var denominatorSum = 0'i64
  for item in 0 ..< n:
    let numerator = input[2 + 2 * item]
    let denominator = input[3 + 2 * item]
    if numerator < 0 or numerator > 1000 or denominator < 1 or denominator > 8:
      return -1
    numerators[item] = numerator
    denominators[item] = denominator
    denominatorSum += denominator
  if requiredValue > denominatorSum: return -1

  var low = 0'i64
  var high = MaxScaledRatio + 1
  while high - low > 1:
    let middle = low + (high - low) div 2
    if ratioFeasible(numerators, denominators, n, requiredWeight, middle):
      low = middle
    else:
      high = middle
  low
