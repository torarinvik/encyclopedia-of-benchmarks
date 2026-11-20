const MaxInputLength = 2
const MaxSieveLimit = 1_000

proc accumulatePowerful(n: int64, primes: var array[MaxSieveLimit + 1, int64],
    primeCount, startIndex: int, product, hProduct: int64, total: var int64) =
  let remaining = n div product
  for primeIndex in startIndex ..< primeCount:
    let prime = primes[primeIndex]
    if prime > remaining div prime: break
    var primePower = prime * prime
    var hPower = prime - 1
    while primePower <= remaining:
      let nextProduct = product * primePower
      let nextHProduct = hProduct * hPower
      total += nextHProduct * (n div nextProduct)
      accumulatePowerful(n, primes, primeCount, primeIndex + 1,
        nextProduct, nextHProduct, total)
      if primePower > remaining div prime: break
      primePower *= prime
      hPower *= prime

proc powerful_number_summatory_sieve*(input: ptr UncheckedArray[int64],
    length: csize_t): int64 {.cdecl, exportc: "powerful_number_summatory_sieve".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  if length != 1: return -1
  let n = input[0]
  if n < 1 or n > 1_000_000: return -1

  var sieveLimit = 1
  while sieveLimit + 1 <= int(n) div (sieveLimit + 1):
    inc sieveLimit
  var composite: array[MaxSieveLimit + 1, bool]
  var primes: array[MaxSieveLimit + 1, int64]
  var primeCount = 0
  if sieveLimit >= 2:
    for candidate in 2 .. sieveLimit:
      if not composite[candidate]:
        primes[primeCount] = int64(candidate)
        inc primeCount
        if candidate <= sieveLimit div candidate:
          var multiple = candidate * candidate
          while multiple <= sieveLimit:
            composite[multiple] = true
            multiple += candidate

  var total = n # The d=1 powerful-number term has h(1)=1.
  accumulatePowerful(n, primes, primeCount, 0, 1, 1, total)
  total
