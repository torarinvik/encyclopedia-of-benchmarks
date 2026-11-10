proc isComposite(n: int64): bool =
  if n < 4: return false
  var divisor = 2'i64
  while divisor <= n div divisor:
    if n mod divisor == 0: return true
    inc divisor
  false

proc modularPower(base, exponent, modulus: int64): int64 =
  result = 1
  var power = base
  var remaining = exponent
  while remaining > 0:
    if remaining mod 2 != 0: result = (result * power) mod modulus
    remaining = remaining div 2
    if remaining > 0: power = (power * power) mod modulus

proc gcd(leftValue, rightValue: int64): int64 =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  left

proc carmichael_number*(value: int64): int64 {.cdecl, exportc: "carmichael_number".} =
  if value < 1 or value > 10000: return -1
  if value < 3 or not isComposite(value): return 0
  var base = 2'i64
  while base < value:
    if gcd(base, value) == 1 and modularPower(base, value - 1, value) != 1: return 0
    inc base
  1
