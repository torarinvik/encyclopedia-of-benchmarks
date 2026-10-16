proc problem50*(ceiling: int64): int64 {.cdecl, exportc: "problem50".} =
  if ceiling < 3 or ceiling > 1_000_000: return -1
  let limit = int(ceiling)
  var isPrime: array[1_000_000, bool]
  for value in 0..<limit: isPrime[value] = true
  isPrime[0] = false
  isPrime[1] = false
  var value = 2
  while value <= (limit - 1) div value:
    if isPrime[value]:
      var multiple = value * value
      while multiple < limit:
        isPrime[multiple] = false
        multiple += value
    inc value
  var primes: array[100_000, int]
  var primeCount = 0
  for candidate in 2..<limit:
    if isPrime[candidate]:
      primes[primeCount] = candidate
      inc primeCount
  var longest = 0
  var largest = 0'i64
  for start in 0..<primeCount:
    let endStart = start + longest
    var sum = 0'i64
    var end = start
    for finish in endStart..<primeCount:
      while end < finish:
        sum += primes[end].int64
        inc end
      if sum >= ceiling: break
      if isPrime[int(sum)]:
        longest = finish - start
        largest = sum
  largest
