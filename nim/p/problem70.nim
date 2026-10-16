const
  MaxN = 10_000_000'i64
  PrimeLimit = 3162
  PrimeCapacity = 500
  SegmentSize = 32768

proc sameDigits(leftValue, rightValue: uint32): bool =
  var counts: array[10, int]
  var number = leftValue
  while number != 0:
    inc counts[int(number mod 10)]
    number = number div 10
  number = rightValue
  while number != 0:
    dec counts[int(number mod 10)]
    number = number div 10
  for count in counts:
    if count != 0: return false
  true

proc problem70*(maxN: int64): int64 {.cdecl, exportc: "problem70".} =
  if maxN < 0 or maxN > MaxN: return -1
  let limit = uint32(maxN)
  var primeFlags: array[PrimeLimit + 1, bool]
  var primes: array[PrimeCapacity, uint32]
  var primeCount = 0
  var value = 2
  while value <= PrimeLimit and value <= int(limit) div value:
    primeFlags[value] = true
    inc value
  var prime = 2
  while prime <= PrimeLimit and prime <= int(limit) div prime:
    if primeFlags[prime]:
      var multiple = prime * prime
      while multiple <= PrimeLimit and multiple <= int(limit) div multiple:
        primeFlags[multiple] = false
        multiple += prime
    inc prime
  value = 2
  while value <= PrimeLimit and value <= int(limit) div value:
    if primeFlags[value]:
      primes[primeCount] = uint32(value)
      inc primeCount
    inc value

  var phi: array[SegmentSize, uint32]
  var remainder: array[SegmentSize, uint32]
  var bestN = 1'u32
  var bestPhi = 0'u32
  var low = 0'u32
  while low <= limit:
    var high = low + uint32(SegmentSize) - 1
    if high < low or high > limit: high = limit
    let length = int(high - low + 1)
    for offset in 0 ..< length:
      phi[offset] = low + uint32(offset)
      remainder[offset] = low + uint32(offset)
    for index in 0 ..< primeCount:
      let factor = primes[index]
      var first = low + (factor - low mod factor) mod factor
      if first < factor: first = factor
      var multiple = first
      while multiple <= high:
        let offset = int(multiple - low)
        phi[offset] -= phi[offset] div factor
        while remainder[offset] mod factor == 0:
          remainder[offset] = remainder[offset] div factor
        if high - multiple < factor: break
        multiple += factor
    for offset in 0 ..< length:
      if remainder[offset] > 1: phi[offset] -= phi[offset] div remainder[offset]
      let number = low + uint32(offset)
      if number >= 2 and uint64(number) * uint64(bestPhi) < uint64(bestN) * uint64(phi[offset]) and sameDigits(number, phi[offset]):
        bestN = number
        bestPhi = phi[offset]
    if high == limit: break
    low = high + 1
  int64(bestN)
