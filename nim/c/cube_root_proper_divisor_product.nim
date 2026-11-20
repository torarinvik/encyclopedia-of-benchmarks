const MaxInputLength = 2
const MaxValue = 600_000
const MaxK = 50_000'i64

proc buildPrimePrefix(prefix: var array[MaxValue + 1, uint32]) =
  prefix[0] = 0
  prefix[1] = 0
  for value in 2 .. MaxValue: prefix[value] = 1
  var prime = 2
  while prime <= MaxValue div prime:
    if prefix[prime] != 0:
      var multiple = prime * prime
      while multiple <= MaxValue:
        prefix[multiple] = 0
        multiple += prime
    inc prime
  for value in 1 .. MaxValue: prefix[value] += prefix[value - 1]

proc isPrime(value: int, prefix: openArray[uint32]): bool =
  value >= 2 and prefix[value] - prefix[value - 1] == 1

proc countTauEight(limit: int, prefix: openArray[uint32]): int64 =
  var count = 0'i64
  var prime = 2'u64
  while true:
    var power = 1'u64
    for exponent in 0 ..< 7:
      if power > uint64(limit) div prime:
        power = uint64(limit) + 1
        break
      power *= prime
    if power > uint64(limit): break
    if isPrime(int(prime), prefix): inc count
    inc prime

  prime = 2
  while true:
    let cube = prime * prime * prime
    if cube > uint64(limit): break
    if isPrime(int(prime), prefix):
      let qMax = int(uint64(limit) div cube)
      count += int64(prefix[qMax])
      if prime <= uint64(qMax): dec count
    inc prime

  prime = 2
  while prime * prime * prime < uint64(limit):
    if isPrime(int(prime), prefix):
      var other = prime + 1
      while true:
        if prime > uint64(limit) div other: break
        let product = prime * other
        let lastPrime = int(uint64(limit) div product)
        if uint64(lastPrime) <= other: break
        if isPrime(int(other), prefix):
          count += int64(prefix[lastPrime] - prefix[int(other)])
        inc other
    inc prime
  count

proc sequenceTerm(k: int64): int64 =
  if k == 1: return 1
  var prefix: array[MaxValue + 1, uint32]
  buildPrimePrefix(prefix)
  let target = k - 1
  if countTauEight(MaxValue, prefix) < target: return -1
  var low = 1
  var high = MaxValue
  while low < high:
    let middle = low + (high - low) div 2
    if countTauEight(middle, prefix) >= target: high = middle
    else: low = middle + 1
  int64(low)

proc cube_root_proper_divisor_product*(input: ptr UncheckedArray[int64],
    length: csize_t): int64
    {.cdecl, exportc: "cube_root_proper_divisor_product".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxK: return -1
  sequenceTerm(input[0])
