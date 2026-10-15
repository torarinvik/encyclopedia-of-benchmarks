proc modPow(baseValue, exponentValue, modulus: int64): int64 =
  var base = baseValue mod modulus
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0:
      result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent shr 1

proc legendreSymbol(residue, prime: int64): int64 =
  let symbol = modPow(residue mod prime, (prime - 1) div 2, prime)
  if symbol == prime - 1: -1 else: symbol

proc tonelli_shanks*(packed: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tonelli_shanks".} =
  if length != 2:
    return -1
  var residue = packed[0]
  let prime = packed[1]
  if prime <= 2 or (prime and 1) == 0 or prime > 1000003 or residue < 0 or residue >= prime:
    return -1
  if residue == 0:
    return 0
  if legendreSymbol(residue, prime) != 1:
    return -1
  if prime mod 4 == 3:
    let root = modPow(residue, (prime + 1) div 4, prime)
    return min(root, prime - root)

  var q = prime - 1
  var s: int64 = 0
  while (q and 1) == 0:
    q = q div 2
    inc s
  var nonResidue: int64 = 2
  while legendreSymbol(nonResidue, prime) != -1:
    inc nonResidue
  var c = modPow(nonResidue, q, prime)
  var r = modPow(residue, (q + 1) div 2, prime)
  var t = modPow(residue, q, prime)
  var remainingS = s
  while t != 1:
    var testPower = t
    var leastI: int64 = 0
    var candidateI: int64 = 1
    while candidateI < remainingS:
      testPower = modPow(testPower, 2, prime)
      if testPower == 1:
        leastI = candidateI
        break
      inc candidateI
    if leastI == 0:
      return -1
    let b = modPow(c, 1'i64 shl (remainingS - leastI - 1), prime)
    r = (r * b) mod prime
    c = (b * b) mod prime
    t = (t * c) mod prime
    remainingS = leastI
  min(r, prime - r)
