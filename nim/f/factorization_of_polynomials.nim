const
  MaxN = 8
  MaxPoly = 9
  MaxFactors = 8
  MaxInput = 12
  MaxOutputBytes = 216

type
  Poly = array[MaxPoly, int64]
  FactorTable = array[MaxFactors, Poly]
  DegreeTable = array[MaxFactors, int]
  MultiplicityTable = array[MaxFactors, int64]

proc powerSmall(base, exponent: int): int =
  result = 1
  for _ in 0 ..< exponent: result *= base

proc monicFromCode(degree, codeInput, prime: int): Poly =
  var code = codeInput
  for i in 0 ..< degree:
    result[i] = int64(code mod prime)
    code = code div prime
  result[degree] = 1

proc exactQuotient(polynomial: Poly, degree: int, divisor: Poly,
    divisorDegree, prime: int, quotient: var Poly): bool =
  if degree < divisorDegree: return false
  var remainder = polynomial
  for i in 0 ..< MaxPoly: quotient[i] = 0
  let quotientDegree = degree - divisorDegree
  for shift in countdown(quotientDegree, 0):
    let factor = remainder[shift + divisorDegree]
    quotient[shift] = factor
    for j in 0 .. divisorDegree:
      var value = (remainder[shift + j] - factor * divisor[j]) mod int64(prime)
      if value < 0: value += int64(prime)
      remainder[shift + j] = value
  for i in 0 ..< divisorDegree:
    if remainder[i] != 0: return false
  true

proc isIrreducible(candidate: Poly, degree, prime: int): bool =
  for divisorDegree in 1 .. (degree div 2):
    let limit = powerSmall(prime, divisorDegree)
    for code in 0 ..< limit:
      let divisor = monicFromCode(divisorDegree, code, prime)
      var quotient: Poly
      if exactQuotient(candidate, degree, divisor, divisorDegree, prime, quotient):
        return false
  true

proc factorize(coefficients: Poly, inputDegree, prime: int,
    factors: var FactorTable, degrees: var DegreeTable,
    multiplicities: var MultiplicityTable): int =
  var work = coefficients
  var workDegree = inputDegree
  for candidateDegree in 1 .. (inputDegree div 2):
    let limit = powerSmall(prime, candidateDegree)
    for code in 0 ..< limit:
      let candidate = monicFromCode(candidateDegree, code, prime)
      if isIrreducible(candidate, candidateDegree, prime):
        var quotient: Poly
        var multiplicity = 0'i64
        while workDegree >= candidateDegree:
          if not exactQuotient(work, workDegree, candidate, candidateDegree, prime, quotient):
            break
          inc multiplicity
          workDegree -= candidateDegree
          work = quotient
        if multiplicity > 0:
          for i in 0 .. candidateDegree: factors[result][i] = candidate[i]
          degrees[result] = candidateDegree
          multiplicities[result] = multiplicity
          inc result
  if workDegree > 0:
    factors[result] = work
    degrees[result] = workDegree
    multiplicities[result] = 1
    inc result
  for i in 0 ..< result:
    for j in i + 1 ..< result:
      var after = degrees[i] > degrees[j]
      if degrees[i] == degrees[j]:
        for k in 0 .. degrees[i]:
          if factors[i][k] != factors[j][k]:
            after = factors[i][k] > factors[j][k]
            break
      if after:
        swap(factors[i], factors[j])
        swap(degrees[i], degrees[j])
        swap(multiplicities[i], multiplicities[j])

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc factorization_of_polynomials*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "factorization_of_polynomials".} =
  if input.isNil or length < csize_t(3) or length > csize_t(MaxInput): return -1
  let degreeValue = input[0]
  let primeValue = input[1]
  if degreeValue < 0 or degreeValue > MaxN.int64 or
      (primeValue != 2 and primeValue != 3 and primeValue != 5): return -1
  let degree = int(degreeValue)
  let prime = int(primeValue)
  if int(length) != degree + 3 or input[degree + 2] != 1: return -1
  var coefficients: Poly
  for i in 0 .. degree:
    coefficients[i] = input[i + 2]
    if coefficients[i] < 0 or coefficients[i] >= primeValue: return -1

  var factors: FactorTable
  var degrees: DegreeTable
  var multiplicities: MultiplicityTable
  let factorCount = factorize(coefficients, degree, prime, factors, degrees, multiplicities)
  var words = 1
  for i in 0 ..< factorCount: words += degrees[i] + 3
  let bytes = words * 8
  if bytes > MaxOutputBytes: return -1
  if output.isNil or capacity < csize_t(bytes): return -2
  var word = 0
  storeLe(output, word * 8, int64(factorCount))
  inc word
  for i in 0 ..< factorCount:
    storeLe(output, word * 8, multiplicities[i])
    inc word
    storeLe(output, word * 8, int64(degrees[i]))
    inc word
    for j in 0 .. degrees[i]:
      storeLe(output, word * 8, factors[i][j])
      inc word
  int64(bytes)
