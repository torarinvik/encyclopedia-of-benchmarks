import std/ffi

const MaxValue = 64
const MaxQueries = 64
const MaxInputLength = 2 + 2 * MaxQueries
const MaxSmall = 8

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc batch_gcd_small_range_precomputed*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "batch_gcd_small_range_precomputed".} =
  if input.isNil or length < 2 or length > csize_t(MaxInputLength + 1): return -1
  let limitValue = input[0]
  let queryValue = input[1]
  if limitValue < 1 or limitValue > int64(MaxValue) or queryValue < 0 or queryValue > int64(MaxQueries): return -1
  let limit = int(limitValue)
  let queries = int(queryValue)
  if length != csize_t(2 + 2 * queries): return -1
  for query in 0 ..< queries:
    let left = input[2 + 2 * query]
    let right = input[3 + 2 * query]
    if left < 0 or left > limitValue or right < 0 or right > limitValue: return -1
  let required = 8 * queries
  if output.isNil or capacity < csize_t(required): return -2

  var least: array[MaxValue + 1, int]
  var primes: array[MaxValue + 1, int]
  var primeCount = 0
  for value in 2 .. limit:
    if least[value] == 0:
      least[value] = value
      primes[primeCount] = value
      inc primeCount
    for index in 0 ..< primeCount:
      let prime = primes[index]
      let composite = value * prime
      if composite > limit or prime > least[value]: break
      least[composite] = prime

  var factors: array[MaxValue + 1, array[3, int]]
  factors[1] = [1, 1, 1]
  for value in 2 .. limit:
    let prime = least[value]
    let quotient = value div prime
    var a = factors[quotient][0] * prime
    var b = factors[quotient][1]
    var c = factors[quotient][2]
    if a > b: swap(a, b)
    if b > c: swap(b, c)
    if a > b: swap(a, b)
    factors[value] = [a, b, c]

  var smallLimit = 1
  while (smallLimit + 1) * (smallLimit + 1) <= limit: inc smallLimit
  var gcdTable: array[MaxSmall + 1, array[MaxSmall + 1, int]]
  for left in 1 .. smallLimit:
    gcdTable[left][0] = left
    for right in 1 ..< left:
      gcdTable[left][right] = gcdTable[right][left mod right]

  for query in 0 ..< queries:
    let left = int(input[2 + 2 * query])
    var remaining = int(input[3 + 2 * query])
    var result = 0
    if left == 0:
      result = remaining
    else:
      result = 1
      for factor in factors[left]:
        let common = if factor <= smallLimit: gcdTable[factor][remaining mod factor]
                     elif remaining mod factor == 0: factor
                     else: 1
        remaining = remaining div common
        result *= common
    storeI64Le(output, 8 * query, int64(result))
  int64(required)
