proc normalize(value, prime: int64): int64 =
  result = value mod prime
  if result < 0: result += prime

proc modularPower(baseValue, exponentValue, prime: int64): int64 =
  var base = normalize(baseValue, prime)
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0:
      result = (result * base) mod prime
    exponent = exponent shr 1
    if exponent > 0:
      base = (base * base) mod prime

proc legendreSymbol(value, prime: int64): int64 =
  let symbol = modularPower(value, (prime - 1) div 2, prime)
  if symbol == prime - 1: -1 else: symbol

proc pairReal(a, b, c, e, radicand, prime: int64): int64 =
  (a * c + radicand * b * e) mod prime

proc pairImaginary(a, b, c, e, prime: int64): int64 =
  (a * e + b * c) mod prime

proc cipolla_modular_square_root*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cipolla_modular_square_root".} =
  if packed.isNil or length != 2: return -1
  let residue = packed[0]
  let prime = packed[1]
  if prime < 3 or prime > 1_000_003 or (prime and 1) == 0 or residue < 0 or residue >= prime:
    return -1
  if residue == 0: return 0
  if legendreSymbol(residue, prime) != 1: return -1

  var parameter = 0'i64
  var radicand = 0'i64
  var found = false
  while parameter < prime:
    radicand = normalize(parameter * parameter - residue, prime)
    if legendreSymbol(radicand, prime) == -1:
      found = true
      break
    inc parameter
  if not found: return -1

  var resultReal = 1'i64
  var resultImaginary = 0'i64
  var baseReal = parameter
  var baseImaginary = 1'i64
  var exponent = (prime + 1) div 2
  while exponent > 0:
    if (exponent and 1) != 0:
      let nextReal = pairReal(resultReal, resultImaginary, baseReal, baseImaginary, radicand, prime)
      let nextImaginary = pairImaginary(resultReal, resultImaginary, baseReal, baseImaginary, prime)
      resultReal = nextReal
      resultImaginary = nextImaginary
    exponent = exponent shr 1
    if exponent > 0:
      let nextBaseReal = pairReal(baseReal, baseImaginary, baseReal, baseImaginary, radicand, prime)
      let nextBaseImaginary = pairImaginary(baseReal, baseImaginary, baseReal, baseImaginary, prime)
      baseReal = nextBaseReal
      baseImaginary = nextBaseImaginary
  if resultImaginary != 0: return -1
  return min(resultReal, prime - resultReal)
