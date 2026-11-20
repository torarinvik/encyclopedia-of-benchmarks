const MaxItems = 12
const MaxParseableInputLength = 27
const RatioBase = 120_001'i64

proc gcdPositive(aInput, bInput: int64): int64 =
  var a = aInput
  var b = bInput
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc chooseCount(n, k: int): int =
  var count = 1
  for i in 1 .. k:
    count = count * (n - i + 1) div i
  count

proc dinkelbach_fixed_cardinality_ratio*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "dinkelbach_fixed_cardinality_ratio".} =
  if input == nil or length < csize_t(2) or length > csize_t(MaxParseableInputLength):
    return -1
  let itemCountValue = input[0]
  let selectedCountValue = input[1]
  if itemCountValue < 1 or itemCountValue > MaxItems or
      selectedCountValue < 1 or selectedCountValue > itemCountValue:
    return -1
  let itemCount = int(itemCountValue)
  let selectedCount = int(selectedCountValue)
  if length != csize_t(2 + 2 * itemCount):
    return -1

  var numerators: array[MaxItems, int64]
  var denominators: array[MaxItems, int64]
  for item in 0 ..< itemCount:
    let numerator = input[2 + 2 * item]
    let denominator = input[3 + 2 * item]
    if numerator < 0 or numerator > 10_000 or denominator < 1 or denominator > 10_000:
      return -1
    numerators[item] = numerator
    denominators[item] = denominator

  var currentNumerator = 0'i64
  var currentDenominator = 1'i64
  let iterationLimit = chooseCount(itemCount, selectedCount)
  for _ in 0 .. iterationLimit:
    var residuals: array[MaxItems, int64]
    var order: array[MaxItems, int]
    for item in 0 ..< itemCount:
      residuals[item] = numerators[item] * currentDenominator - currentNumerator * denominators[item]
      order[item] = item
    for position in 1 ..< itemCount:
      let candidate = order[position]
      var insertion = position
      while insertion > 0:
        let previous = order[insertion - 1]
        if residuals[candidate] > residuals[previous] or
            (residuals[candidate] == residuals[previous] and candidate < previous):
          order[insertion] = previous
          dec insertion
        else:
          break
      order[insertion] = candidate

    var numeratorTotal = 0'i64
    var denominatorTotal = 0'i64
    for rank in 0 ..< selectedCount:
      let item = order[rank]
      numeratorTotal += numerators[item]
      denominatorTotal += denominators[item]

    let residualTotal = numeratorTotal * currentDenominator - currentNumerator * denominatorTotal
    if residualTotal == 0:
      let divisor = gcdPositive(numeratorTotal, denominatorTotal)
      return (numeratorTotal div divisor) * RatioBase + denominatorTotal div divisor
    if residualTotal < 0:
      return -1
    let divisor = gcdPositive(numeratorTotal, denominatorTotal)
    currentNumerator = numeratorTotal div divisor
    currentDenominator = denominatorTotal div divisor

  -1
