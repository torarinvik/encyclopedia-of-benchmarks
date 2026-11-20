const
  SieveLimit = 32_000
  PhiRows = 12
  PhiColumns = 30_000
  MaxInput = 1_000_000_000'i64

type PrimeSumContext = object
  primes: seq[int64]
  primeCount: seq[int]
  primeSum: seq[int64]
  phi: seq[int64]

proc buildContext(): PrimeSumContext =
  var composite = newSeq[bool](SieveLimit + 1)
  var candidate = 2
  while candidate * candidate <= SieveLimit:
    if not composite[candidate]:
      var multiple = candidate * candidate
      while multiple <= SieveLimit:
        composite[multiple] = true
        multiple += candidate
    candidate += 1

  result.primeCount = newSeq[int](SieveLimit + 1)
  result.primeSum = newSeq[int64](SieveLimit + 1)
  for n in 2 .. SieveLimit:
    if not composite[n]: result.primes.add(n.int64)
    result.primeCount[n] = result.primeCount[n - 1] + (if composite[n]: 0 else: 1)
    result.primeSum[n] = result.primeSum[n - 1] + (if composite[n]: 0'i64 else: n.int64)

  result.phi = newSeq[int64](PhiRows * PhiColumns)
  for n in 0 ..< PhiColumns:
    result.phi[n] = n.int64 * (n.int64 + 1) div 2
  for row in 1 ..< PhiRows:
    let prime = result.primes[row - 1]
    let previous = (row - 1) * PhiColumns
    let current = row * PhiColumns
    for n in 0 ..< PhiColumns:
      result.phi[current + n] = result.phi[previous + n] -
        prime * result.phi[previous + n div prime.int]

proc sqrtFloor(n: int64): int64 =
  var low = 0'i64
  var high = n + 1
  while low + 1 < high:
    let middle = low + (high - low) div 2
    if middle <= n div middle: low = middle else: high = middle
  low

proc cbrtFloor(n: int64): int64 =
  var low = 0'i64
  var high = 1'i64
  while high * high * high <= n: high *= 2
  while low + 1 < high:
    let middle = low + (high - low) div 2
    if middle * middle * middle <= n: low = middle else: high = middle
  low

proc weightedPhi(ctx: var PrimeSumContext, n: int64, count: int): int64 =
  if n <= 0: return 0
  if count == 0: return n * (n + 1) div 2
  let prime = ctx.primes[count - 1]
  if n <= prime: return 1
  if count < PhiRows and n < PhiColumns.int64:
    return ctx.phi[count * PhiColumns + n.int]
  if n < SieveLimit.int64 and prime * prime >= n:
    return ctx.primeSum[n.int] - ctx.primeSum[prime.int] + 1
  if n < SieveLimit.int64 and prime * prime * prime >= n:
    var total = ctx.primeSum[n.int] - ctx.primeSum[prime.int] + 1
    let limit = ctx.primeCount[sqrtFloor(n).int]
    for index in count ..< limit:
      let other = ctx.primes[index]
      total += other * (ctx.primeSum[(n div other).int] - ctx.primeSum[other.int - 1])
    return total
  weightedPhi(ctx, n, count - 1) - prime * weightedPhi(ctx, n div prime, count - 1)

proc sumPrimes(ctx: var PrimeSumContext, n: int64): int64 =
  if n <= SieveLimit.int64: return ctx.primeSum[n.int]
  let cube = cbrtFloor(n).int
  let square = sqrtFloor(n).int
  let first = ctx.primeCount[cube]
  let last = ctx.primeCount[square]
  result = weightedPhi(ctx, n, first) + ctx.primeSum[cube] - 1
  for index in first ..< last:
    let prime = ctx.primes[index]
    let quotient = n div prime
    result -= (sumPrimes(ctx, quotient) - ctx.primeSum[prime.int - 1]) * prime

proc fast_prime_sums*(value: int64): int64 {.cdecl, exportc: "fast_prime_sums".} =
  if value < 0 or value > MaxInput: return -1
  var context = buildContext()
  sumPrimes(context, value)
