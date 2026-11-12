const
  Modulus = 469_762_049'i64
  MaxN = 100_000_000'i64

proc floorSqrt(value: int64): int64 =
  var low = 1'i64
  var high = 31_623'i64
  while low < high:
    let middle = low + (high - low + 1) div 2
    if middle <= value div middle: low = middle else: high = middle - 1
  low

proc normalize(value: int64): int64 =
  let remainder = value mod Modulus
  if remainder < 0: remainder + Modulus else: remainder

proc triangularMod(value: int64): int64 =
  var left = value
  var right = value + 1
  if (left and 1) == 0: left = left div 2 else: right = right div 2
  ((left mod Modulus) * (right mod Modulus)) mod Modulus

proc valueIndex(value, n, root: int64, size: int): int =
  if value <= root: size - int(value) else: int(n div value)

proc solve(n, a, b: int64): int64 =
  let root = floorSqrt(n)
  var highCount = int(n div root)
  while highCount > 1 and n div int64(highCount - 1) == root: dec highCount
  let size = highCount + int(root)
  var quotients = newSeq[int64](size)
  var primeCount = newSeq[int64](size)
  var primeSum = newSeq[int64](size)
  for index in 1 ..< highCount: quotients[index] = n div int64(index)
  for value in 1'i64 .. root: quotients[size - int(value)] = value

  var composite = newSeq[bool](int(root) + 1)
  var primes: seq[int64] = @[]
  for value in 2'i64 .. root:
    if composite[int(value)]: continue
    primes.add(value)
    if value <= root div value:
      var multiple = value * value
      while multiple <= root:
        composite[int(multiple)] = true
        multiple += value

  for index in 1 ..< size:
    primeCount[index] = quotients[index] - 1
    primeSum[index] = normalize(triangularMod(quotients[index]) - 1)
  var precedingCount = 0'i64
  var precedingSum = 0'i64
  for prime in primes:
    let square = prime * prime
    for index in 1 ..< size:
      if quotients[index] < square: break
      let quotientIndex = valueIndex(quotients[index] div prime, n, root, size)
      primeCount[index] -= primeCount[quotientIndex] - precedingCount
      let sumDelta = normalize(primeSum[quotientIndex] - precedingSum)
      primeSum[index] = normalize(primeSum[index] - (prime mod Modulus) * sumDelta)
    inc precedingCount
    precedingSum = normalize(precedingSum + prime)

  var primeF = newSeq[int64](size)
  for index in 1 ..< size:
    primeF[index] = (a * (primeCount[index] mod Modulus) + b * primeSum[index]) mod Modulus
  var values = newSeq[int64](size)
  var nextValues = newSeq[int64](size)
  for index in 0 ..< size:
    values[index] = primeF[index]
    nextValues[index] = primeF[index]
  var position = primes.len
  while position > 0:
    dec position
    let prime = primes[position]
    var power = prime
    var exponent = 1'i64
    let primePrefix = primeF[valueIndex(prime, n, root, size)]
    while n div prime >= power:
      let local = (a * exponent + b * prime) mod Modulus
      let nextLocal = (a * (exponent + 1) + b * prime) mod Modulus
      let nextPower = power * prime
      for index in 1 ..< size:
        if nextPower > quotients[index]: break
        let quotientIndex = valueIndex(quotients[index] div power, n, root, size)
        let nonPrimeSum = normalize(values[quotientIndex] - primePrefix)
        nextValues[index] = normalize(nextValues[index] + local * nonPrimeSum + nextLocal)
      power = nextPower
      inc exponent
    let copied = min(size, valueIndex(prime * prime, n, root, size) + 1)
    for index in 0 ..< copied: values[index] = nextValues[index]
  normalize(values[valueIndex(n, n, root, size)] + 1)

proc sum_of_multiplicative_function_large*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "sum_of_multiplicative_function_large".} =
  if input == nil or length != 3: return -1
  let n = input[0]
  let a = input[1]
  let b = input[2]
  if n < 1 or n > MaxN or a < 0 or a >= Modulus or b < 0 or b >= Modulus: return -1
  solve(n, a, b)
