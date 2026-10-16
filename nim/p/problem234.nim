const MaxLimit = 999966663333'i64

proc problem234*(limit: int64): int64 {.cdecl, exportc: "problem234".} =
  if limit < 0 or limit > MaxLimit: return -1
  var composite: array[1_000_100, bool]
  var primes: array[80_000, int64]
  var primeCount = 0
  var root = 0'i64
  while root + 1 <= limit div (root + 1): inc root
  let sieveEnd = int(root) + 100
  for p in 2..<sieveEnd:
    if composite[p]: continue
    primes[primeCount] = int64(p)
    inc primeCount
    if p * p < sieveEnd:
      var multiple = p * p
      while multiple < sieveEnd:
        composite[multiple] = true
        multiple += p
  var total = 0'i64
  var index = 0
  var p = primes[index]
  while p * p <= limit:
    let q = primes[index + 1]
    let lower = p * p
    var upper = q * q
    var current = lower + p
    while upper > current and current <= limit:
      total += current
      current += p
    while upper - q > limit: upper -= q
    current = upper - q
    while current > lower:
      total += current
      current -= q
    current = 0
    while upper > current and current <= limit:
      if current <= lower:
        current += p * q
        continue
      if current > limit: break
      total -= 2 * current
      current += p * q
    p = q
    inc index
  total
