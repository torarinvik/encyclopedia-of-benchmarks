const MaxPrime = 1_000_000'i64

proc problem131IsPrime(number: int64): bool =
  if number < 2: return false
  var divisor = 2'i64
  while divisor <= number div divisor:
    if number mod divisor == 0: return false
    inc divisor
  true

proc problem131*(maxPrime: int64): int64 {.cdecl, exportc: "problem131".} =
  if maxPrime < 0 or maxPrime > MaxPrime: return -1
  var primesCount = 0'i64
  var cubeIndex = 1'i64
  var primeCandidate = 7'i64
  while primeCandidate < maxPrime:
    if problem131IsPrime(primeCandidate): inc primesCount
    inc cubeIndex
    primeCandidate += 6 * cubeIndex
  primesCount
