## Legendre's formula for the exponent of prime p in n!.
proc largestPowerPrime(value: uint64): bool =
  if value < 2: return false
  var divisor = 2'u64
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    divisor += 1
  return true

proc largest_power*(n, p: uint64): int64 {.cdecl, exportc: "largest_power".} =
  if n > 4294967295'u64 or p > 65535'u64 or not largestPowerPrime(p): return -1
  var quotient = n
  var total = 0'i64
  while quotient != 0:
    quotient = quotient div p
    total += int64(quotient)
  return total
