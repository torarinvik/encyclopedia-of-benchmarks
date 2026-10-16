const LIMIT = 10_000

proc digitSignature(value: int64): int64 =
  var digits = [value div 1000, value div 100 mod 10, value div 10 mod 10, value mod 10]
  for first in 0 .. 3:
    for second in first + 1 .. 3:
      if digits[first] > digits[second]:
        swap(digits[first], digits[second])
  digits[0] * 1000 + digits[1] * 100 + digits[2] * 10 + digits[3]

proc problem49*(ignored: int64): int64 {.cdecl, exportc: "problem49".} =
  if ignored != 0: return -1
  var primeFlags: array[LIMIT, bool]
  for value in 2 ..< LIMIT: primeFlags[value] = true
  for prime in 2 ..< LIMIT:
    if prime * prime >= LIMIT: break
    if not primeFlags[prime]: continue
    var multiple = prime * prime
    while multiple < LIMIT:
      primeFlags[multiple] = false
      multiple += prime
  var primes: array[1100, int64]
  var signatures: array[LIMIT, int64]
  var primeCount = 0
  var value = 1001
  while value < LIMIT:
    if primeFlags[value]:
      primes[primeCount] = int64(value)
      inc primeCount
      signatures[value] = digitSignature(int64(value))
    value += 2
  var seenSignatures: array[LIMIT, bool]
  var best = 0'i64
  for seed in 0 ..< primeCount:
    let signature = int(signatures[int(primes[seed])])
    if seenSignatures[signature]: continue
    seenSignatures[signature] = true
    var group: array[24, int64]
    var groupCount = 0
    for candidate in 0 ..< primeCount:
      let candidateValue = primes[candidate]
      if signatures[int(candidateValue)] == int64(signature):
        group[groupCount] = candidateValue
        inc groupCount
    var found = false
    var first = 0
    while first < groupCount and not found:
      var second = first + 1
      while second < groupCount and not found:
        var third = second + 1
        while third < groupCount:
          if group[second] - group[first] == group[third] - group[second]:
            let sequence = group[first] * 100_000_000 + group[second] * 10_000 + group[third]
            if sequence > best: best = sequence
            found = true
            break
          inc third
        inc second
      inc first
  best
