const
  Modulus = 469_762_049'i64
  MaxN = 10_000_000'i64

proc floorSqrt(value: int64): int64 =
  var low = 1'i64
  var high = 3162'i64
  while low < high:
    let middle = low + (high - low + 1) div 2
    if middle <= value div middle: low = middle else: high = middle - 1
  low

proc normalize(value: int64): int64 =
  let remainder = value mod Modulus
  if remainder < 0: remainder + Modulus else: remainder

proc quotientAt(index: int, n: int64, highCount, size: int): int64 =
  if index < highCount: n div int64(index) else: int64(size - index)

proc valueIndex(value, n, root: int64, size: int): int =
  if value <= root: size - int(value) else: int(n div value)

proc upperBound(primes: seq[int64], value: int64): int =
  var low = 0
  var high = primes.len
  while low < high:
    let middle = low + (high - low) div 2
    if primes[middle] <= value: low = middle + 1 else: high = middle
  low

proc applySkippedPrimeRange(index, stage: int, smallLo, smallHi: seq[uint32],
    simpleCursor: var seq[uint32], prefixG: seq[int64], smoothSum: var seq[int64]) =
  var next = uint32(stage + 1)
  if next < smallLo[index]: next = smallLo[index]
  if next > smallHi[index]: next = smallHi[index]
  let old = simpleCursor[index]
  if next < old:
    smoothSum[index] = normalize(smoothSum[index] + prefixG[int(old)] - prefixG[int(next)])
    simpleCursor[index] = next

proc applySkippedPowerSums(index, stage: int, smallLo, smallHi: seq[uint32],
    gCursor: var seq[uint32], prefixSum: seq[int64],
    gZero, gOne: var seq[int64]) =
  var next = uint32(stage)
  if next < smallLo[index]: next = smallLo[index]
  if next > smallHi[index]: next = smallHi[index]
  let old = gCursor[index]
  if next > old:
    gZero[index] = normalize(gZero[index] - int64(next - old))
    gOne[index] = normalize(gOne[index] - (prefixSum[int(next)] - prefixSum[int(old)]))
    gCursor[index] = next

proc smallValue(value: int64, smallest: seq[uint32], a, b: int64): int64 =
  var remaining = value
  var result = 1'i64
  while remaining > 1:
    let prime = int64(smallest[int(remaining)])
    var exponent = 0'i64
    while remaining mod prime == 0:
      remaining = remaining div prime
      inc exponent
    result = result * ((a * exponent + b * prime) mod Modulus) mod Modulus
  result

proc solve(n, a, b: int64): int64 =
  let root = floorSqrt(n)
  var highCount = int(n div root)
  while highCount > 1 and n div int64(highCount - 1) == root: dec highCount
  let size = highCount + int(root)

  var smallest = newSeq[uint32](int(root) + 1)
  var primes: seq[int64] = @[]
  for value in 2'i64 .. root:
    if smallest[int(value)] != 0: continue
    smallest[int(value)] = uint32(value)
    primes.add(value)
    if value <= root div value:
      var multiple = value * value
      while multiple <= root:
        if smallest[int(multiple)] == 0: smallest[int(multiple)] = uint32(value)
        multiple += value

  var prefixSum = newSeq[int64](primes.len + 1)
  var prefixG = newSeq[int64](primes.len + 1)
  for index, prime in primes:
    prefixSum[index + 1] = normalize(prefixSum[index] + prime)
    prefixG[index + 1] = normalize(prefixG[index] + a + b * prime)

  var gZero = newSeq[int64](size)
  var gOne = newSeq[int64](size)
  var smoothSum = newSeq[int64](size)
  var smallLo = newSeq[uint32](size)
  var smallHi = newSeq[uint32](size)
  var simpleCursor = newSeq[uint32](size)
  var gCursor = newSeq[uint32](size)
  for index in 1 ..< size:
    let value = quotientAt(index, n, highCount, size)
    smallLo[index] = uint32(upperBound(primes, floorSqrt(value)))
    smallHi[index] = uint32(upperBound(primes, value))
    simpleCursor[index] = smallHi[index]
    gCursor[index] = smallLo[index]
    smoothSum[index] = 1
    gZero[index] = value mod Modulus
    var left = value
    var right = value + 1
    if (left and 1) == 0: left = left div 2 else: right = right div 2
    gOne[index] = (left mod Modulus) * (right mod Modulus) mod Modulus

  for stage, prime in primes:
    let square = prime * prime
    for index in 1 ..< size:
      let value = quotientAt(index, n, highCount, size)
      if value < square: break
      let child = valueIndex(value div prime, n, root, size)
      applySkippedPowerSums(child, stage, smallLo, smallHi, gCursor, prefixSum, gZero, gOne)
      gZero[index] = normalize(gZero[index] - gZero[child])
      gOne[index] = normalize(gOne[index] - prime * gOne[child])
  for index in 1 ..< size:
    applySkippedPowerSums(index, primes.len, smallLo, smallHi, gCursor, prefixSum, gZero, gOne)

  if primes.len > 0:
    for stage in countdown(primes.high, 0):
      let prime = primes[stage]
      let square = prime * prime
      for index in 1 ..< size:
        let value = quotientAt(index, n, highCount, size)
        if value < square: break
        applySkippedPrimeRange(index, stage, smallLo, smallHi, simpleCursor, prefixG, smoothSum)
        var power = prime
        var exponent = 1'i64
        while power <= value:
          let child = valueIndex(value div power, n, root, size)
          applySkippedPrimeRange(child, stage, smallLo, smallHi, simpleCursor, prefixG, smoothSum)
          let local = (a * exponent + b * prime) mod Modulus
          smoothSum[index] = normalize(smoothSum[index] + local * smoothSum[child])
          power *= prime
          inc exponent

  var answer = smoothSum[1]
  for value in 1'i64 .. root:
    let quotientIndex = valueIndex(n div value, n, root, size)
    let largePrimeSum = normalize(
      a * normalize(gZero[quotientIndex] - 1) +
      b * normalize(gOne[quotientIndex] - 1))
    answer = normalize(answer + smallValue(value, smallest, a, b) * largePrimeSum)
  answer

proc zhouge_summatory_multiplicative_function*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "zhouge_summatory_multiplicative_function".} =
  if input == nil or length != 3: return -1
  let n = input[0]
  let a = input[1]
  let b = input[2]
  if n < 1 or n > MaxN or a < 0 or a >= Modulus or b < 0 or b >= Modulus: return -1
  solve(n, a, b)
