## Deterministic Miller-Rabin for signed 32-bit inputs.
proc modPower(baseValue, exponentValue, modulus: int64): int64 =
  var base = baseValue mod modulus
  var exponent = exponentValue
  var result = 1'i64
  while exponent > 0:
    if exponent mod 2 != 0: result = (result * base) mod modulus
    base = (base * base) mod modulus
    exponent = exponent div 2
  return result

proc passesBase(n, base, oddPart, powersOfTwo: int64): bool =
  var value = modPower(base, oddPart, n)
  if value == 1 or value == n - 1: return true
  var round = 1'i64
  while round < powersOfTwo:
    value = (value * value) mod n
    if value == n - 1: return true
    round += 1
  return false

proc miller_rabin*(n: int64): int64 {.cdecl, exportc: "miller_rabin".} =
  if n < 2: return 0
  if n > 2147483647'i64: return -1
  if n == 2 or n == 3 or n == 5 or n == 7: return 1
  if n mod 2 == 0 or n mod 3 == 0 or n mod 5 == 0 or n mod 7 == 0: return 0

  var oddPart = n - 1
  var powersOfTwo = 0'i64
  while oddPart mod 2 == 0:
    oddPart = oddPart div 2
    powersOfTwo += 1
  if not passesBase(n, 2, oddPart, powersOfTwo): return 0
  if not passesBase(n, 3, oddPart, powersOfTwo): return 0
  if not passesBase(n, 5, oddPart, powersOfTwo): return 0
  if not passesBase(n, 7, oddPart, powersOfTwo): return 0
  return 1
