const MaxProduct = 16_777_216'i64

proc modularInverse(value, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  var remainder = modulus
  var oldCoefficient = 1'i64
  var coefficient = 0'i64
  while remainder != 0:
    let quotient = oldRemainder div remainder
    let nextRemainder = oldRemainder - quotient * remainder
    oldRemainder = remainder
    remainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * coefficient
    oldCoefficient = coefficient
    coefficient = nextCoefficient
  oldCoefficient = oldCoefficient mod modulus
  if oldCoefficient < 0: oldCoefficient += modulus
  oldCoefficient

proc generalized_chinese_remainder_theorem*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "generalized_chinese_remainder_theorem".} =
  if input == nil or length < 1 or length > 10: return -1
  let countValue = input[0]
  if countValue < 1 or countValue > 4: return -1
  let count = int(countValue)
  if length != csize_t(1 + 2 * count): return -1

  var product = 1'i64
  for index in 0..<count:
    let residue = input[1 + 2 * index]
    let modulus = input[2 + 2 * index]
    if modulus < 2 or modulus > 64 or residue < 0 or residue >= modulus: return -1
    if product > MaxProduct div modulus: return -1
    product *= modulus

  var powers: array[65, int64]
  var residues: array[65, int64]
  for primeIndex in 0..64:
    powers[primeIndex] = 0
    residues[primeIndex] = 0
  for index in 0..<count:
    let residue = input[1 + 2 * index]
    var remaining = input[2 + 2 * index]
    var prime = 2'i64
    while prime <= remaining:
      if remaining mod prime == 0:
        var primePower = 1'i64
        while remaining mod prime == 0:
          remaining = remaining div prime
          primePower *= prime
        if primePower > powers[int(prime)]:
          powers[int(prime)] = primePower
          residues[int(prime)] = residue mod primePower
      prime += 1
  for index in 0..<count:
    let residue = input[1 + 2 * index]
    var remaining = input[2 + 2 * index]
    var prime = 2'i64
    while prime <= remaining:
      if remaining mod prime == 0:
        var primePower = 1'i64
        while remaining mod prime == 0:
          remaining = remaining div prime
          primePower *= prime
        if residues[int(prime)] mod primePower != residue mod primePower: return -2
      prime += 1

  var solution = 0'i64
  var combinedModulus = 1'i64
  for primeIndex in 2..64:
    let modulus = powers[primeIndex]
    if modulus == 0: continue
    let inverse = modularInverse(combinedModulus mod modulus, modulus)
    var difference = (residues[primeIndex] - solution mod modulus) mod modulus
    if difference < 0: difference += modulus
    let multiplier = difference * inverse mod modulus
    solution += combinedModulus * multiplier
    combinedModulus *= modulus
    solution = solution mod combinedModulus
  solution
