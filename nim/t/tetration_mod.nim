const maxValue = 1_000_000_000'i64

proc totient(value: int64): int64 =
  var result = value
  var remaining = value
  if remaining mod 2 == 0:
    result -= result div 2
    while remaining mod 2 == 0: remaining = remaining div 2
  var factor = 3'i64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      result -= result div factor
      while remaining mod factor == 0: remaining = remaining div factor
    factor += 2
  if remaining > 1: result -= result div remaining
  result

proc powerCapped(base, exponentInput, cap: int64): int64 =
  var result = 1'i64
  var factor = min(base, cap)
  var exponent = exponentInput
  while exponent > 0:
    if exponent mod 2 != 0:
      result *= factor
      if result >= cap: return cap
    exponent = exponent div 2
    if exponent > 0:
      factor *= factor
      if factor >= cap: factor = cap
  result

proc towerCapped(base, heightInput, cap: int64): int64 =
  if heightInput == 0: return min(1'i64, cap)
  if base == 0: return if heightInput mod 2 == 0: 1 else: 0
  if base == 1: return min(1'i64, cap)
  var value = 1'i64
  if value >= cap: return cap
  var height = heightInput
  while height > 0:
    value = powerCapped(base, value, cap)
    if value >= cap: return cap
    height -= 1
  value

proc modularPower(baseInput, exponentInput, modulus: int64): int64 =
  var result = 1'i64 mod modulus
  var base = baseInput mod modulus
  var exponent = exponentInput
  while exponent > 0:
    if exponent mod 2 != 0: result = (result * base) mod modulus
    exponent = exponent div 2
    base = (base * base) mod modulus
  result

proc tetration(base, height, modulus: int64): int64 =
  if modulus == 1: return 0
  if height == 0: return 1'i64 mod modulus
  if height == 1: return base mod modulus
  let exponentModulus = totient(modulus)
  var exponent = tetration(base, height - 1, exponentModulus)
  if towerCapped(base, height - 1, exponentModulus) >= exponentModulus:
    exponent += exponentModulus
  modularPower(base, exponent, modulus)

proc tetration_mod*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "tetration_mod".} =
  if values == nil or length != 3: return -1
  let base = values[0]
  let height = values[1]
  let modulus = values[2]
  if base < 0 or base > maxValue or height < 0 or height > maxValue or
      modulus < 1 or modulus > maxValue: return -1
  tetration(base, height, modulus)
