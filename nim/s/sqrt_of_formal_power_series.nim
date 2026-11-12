const
  Modulus = 998_244_353'i64
  MaxN = 64
  MaxInput = 66

proc modPower(baseValue, exponentValue: int64): int64 =
  var base = baseValue mod Modulus
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if exponent mod 2 != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent div 2
  result

proc modSquareRoot(value: int64): int64 =
  if value == 0: return 0
  if modPower(value, (Modulus - 1) div 2) != 1: return -1
  var oddPart = Modulus - 1
  var twos = 0
  while oddPart mod 2 == 0:
    oddPart = oddPart div 2
    inc twos
  var nonResidue = 2'i64
  while modPower(nonResidue, (Modulus - 1) div 2) != Modulus - 1: inc nonResidue
  var c = modPower(nonResidue, oddPart)
  var root = modPower(value, (oddPart + 1) div 2)
  var remainder = modPower(value, oddPart)
  var order = twos
  while remainder != 1:
    var index = 1
    var probe = remainder * remainder mod Modulus
    while index < order and probe != 1:
      probe = probe * probe mod Modulus
      inc index
    if index >= order or probe != 1: return -1
    var exponent = 1'i64
    for bit in 0 ..< (order - index - 1): exponent = exponent * 2
    let factor = modPower(c, exponent)
    root = root * factor mod Modulus
    let factorSquared = factor * factor mod Modulus
    remainder = remainder * factorSquared mod Modulus
    c = factorSquared
    order = index
  min(root, Modulus - root)

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc sqrt_of_formal_power_series*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sqrt_of_formal_power_series".} =
  if input == nil or length < 2 or length > csize_t(MaxInput): return -1
  let nValue = input[0]
  if nValue < 1 or nValue > MaxN: return -1
  let n = int(nValue)
  if int(length) != n + 1: return -1
  for i in 0 ..< n:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
  let bytes = 8 * n
  if output == nil or int(capacity) < bytes: return -2

  var result: array[MaxN, int64]
  var valuation = 0
  while valuation < n and input[valuation + 1] == 0: inc valuation
  if valuation == n:
    for i in 0 ..< n: storeLe(output, 8 * i, 0)
    return int64(bytes)
  if valuation mod 2 != 0:
    storeLe(output, 0, -1)
    return 8
  let shift = valuation div 2
  let leadingRoot = modSquareRoot(input[valuation + 1])
  if leadingRoot < 0:
    storeLe(output, 0, -1)
    return 8
  let inverseTwiceRoot = modPower((2 * leadingRoot) mod Modulus, Modulus - 2)
  let width = n - valuation
  result[shift] = leadingRoot
  for degree in 1 ..< width:
    var crossTerms = 0'i64
    for i in 1 ..< degree:
      crossTerms = (crossTerms + result[shift + i] * result[shift + degree - i]) mod Modulus
    var delta = (input[valuation + degree + 1] - crossTerms) mod Modulus
    if delta < 0: delta += Modulus
    result[shift + degree] = delta * inverseTwiceRoot mod Modulus
  for i in 0 ..< n: storeLe(output, 8 * i, result[i])
  int64(bytes)
