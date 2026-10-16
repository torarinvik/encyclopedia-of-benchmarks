const MaxN = 10_000_000_000'i64

type PrimeArray = array[100_001, int64]

proc isPrime(value: int64, primes: openArray[int64], count: int): bool =
  for index in 0..<count:
    let prime = primes[index]
    if value mod prime == 0: return false
  true

proc problem111*(n: int64): int64 {.cdecl, exportc: "problem111".} =
  if n < 1000 or n > MaxN: return -1
  var composite: array[100_002, bool]
  var primes: PrimeArray
  var primeCount = 0
  var root = 0'i64
  while root + 1 <= n div (root + 1): inc root
  let sieveLimit = int(root) + 1
  for p in 2..sieveLimit:
    if composite[p]: continue
    primes[primeCount] = int64(p)
    inc primeCount
    if p * p <= sieveLimit:
      var multiple = p * p
      while multiple <= sieveLimit:
        composite[multiple] = true
        multiple += p
  var digits = 0
  var copy = n
  while copy > 0:
    inc digits
    copy = copy div 10
  let width = digits - 1
  let repeatedTwo = width - 2
  var total = 0'i64
  for i in 1..9:
    for j in 1..9:
      var value = int64(i)
      for _ in 0..<(width - 2): value *= 10
      value = value * 10 + int64(j)
      if isPrime(value, primes, primeCount): total += value
  var oneDigit: array[10, bool]
  for i in 1..9:
    for j in 0..<width:
      for k in 0..9:
        var value = 0'i64
        for position in 0..<width:
          value = value * 10 + (if position == j: int64(k) else: int64(i))
        if isPrime(value, primes, primeCount):
          oneDigit[i] = true
          total += value
  for i in 1..9:
    if oneDigit[i]: continue
    for j in 0..repeatedTwo:
      for k in 0..(repeatedTwo - j):
        for m1 in 0..9:
          if m1 == 0 and j == 0: continue
          for m2 in 0..9:
            var value = 0'i64
            for position in 0..<width:
              let digit = if position == j: m1 elif position == j + k + 1: m2 else: i
              value = value * 10 + int64(digit)
            if isPrime(value, primes, primeCount): total += value
  total
