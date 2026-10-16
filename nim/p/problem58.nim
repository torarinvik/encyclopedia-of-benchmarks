proc isPrime(value: int64): bool =
  if value < 2: return false
  if value < 4: return true
  if value mod 2 == 0 or value mod 3 == 0: return false
  var divisor = 5'i64
  while divisor <= value div divisor:
    if value mod divisor == 0 or value mod (divisor + 2) == 0: return false
    divisor += 6
  true

proc problem58*(ratio: float64): float64 {.cdecl, exportc: "problem58".} =
  if ratio != ratio or ratio < 0.1 or ratio > 0.6: return -1.0
  var side = 3'i64
  var primeCount = 3'i64
  while float64(primeCount) / float64(2 * side - 1) >= ratio:
    let square = side * side
    let step = side + 1
    if isPrime(square + step): inc primeCount
    if isPrime(square + 2 * step): inc primeCount
    if isPrime(square + 3 * step): inc primeCount
    side += 2
  float64(side)
