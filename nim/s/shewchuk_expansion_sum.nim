const
  MaxTerms = 16
  MaxLength = 34
  MaxMantissa = 16777216'i64
  OutputScale = 1073741824.0

type SumPair = tuple[high, low: float64]

proc twoSum(a, b: float64): SumPair =
  let rounded = a+b
  let bVirtual = rounded-a
  let aVirtual = rounded-bVirtual
  let bRoundoff = b-bVirtual
  let aRoundoff = a-aVirtual
  (rounded, aRoundoff+bRoundoff)

proc growExpansion(expansion: array[MaxTerms+1, float64], count: int,
                   value: float64, grown: var array[MaxTerms+1, float64]): int =
  var q = value
  var grownCount = 0
  for i in 0 ..< count:
    let pair = twoSum(q, expansion[i])
    if pair.low != 0.0:
      grown[grownCount] = pair.low
      inc grownCount
    q = pair.high
  if q != 0.0 or grownCount == 0:
    grown[grownCount] = q
    inc grownCount
  grownCount

proc shewchuk_expansion_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "shewchuk_expansion_sum".} =
  if input == nil or length < 1 or length > csize_t(MaxLength): return -1
  if input[0] < 0 or input[0] > int64(MaxTerms): return -1
  let n = int(input[0])
  if int(length) != 1+2*n: return -1

  var expansion: array[MaxTerms+1, float64]
  var grown: array[MaxTerms+1, float64]
  var expansionCount = 0
  for i in 0 ..< n:
    let mantissa = input[1+2*i]
    let exponent = input[2+2*i]
    if mantissa < -MaxMantissa or mantissa > MaxMantissa or exponent < -30 or exponent > 0:
      return -1
    var value = float64(mantissa)
    var shift = 0'i64
    while shift > exponent:
      value *= 0.5
      dec shift
    if value != 0.0:
      let grownCount = growExpansion(expansion, expansionCount, value, grown)
      for j in 0 ..< grownCount: expansion[j] = grown[j]
      expansionCount = grownCount
  var result = (1'i64 shl 58)+1
  for i in 0 ..< expansionCount:
    result += int64(expansion[i]*OutputScale)
  result
