type I64Array = ptr UncheckedArray[int64]

proc gcdI64(aInput, bInput: int64): int64 =
  var a = aInput
  var b = bInput
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc powModI64(baseInput, exponentInput, modulus: int64): int64 =
  var base = baseInput mod modulus
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if exponent mod 2 != 0: result = result * base mod modulus
    base = base * base mod modulus
    exponent = exponent div 2
  result

proc totientI64(value: int64): int64 =
  var remaining = value
  var result = value
  var prime = 2'i64
  while prime * prime <= remaining:
    if remaining mod prime == 0:
      result = result div prime * (prime - 1)
      while remaining mod prime == 0: remaining = remaining div prime
    inc prime
  if remaining > 1: result = result div remaining * (remaining - 1)
  result

proc reduceOrder(base, modulus, initialOrder: int64): int64 =
  var remaining = initialOrder
  var order = initialOrder
  var prime = 2'i64
  while prime * prime <= remaining:
    if remaining mod prime == 0:
      while remaining mod prime == 0: remaining = remaining div prime
      while order mod prime == 0 and powModI64(base, order div prime, modulus) == 1:
        order = order div prime
    inc prime
  if remaining > 1:
    while order mod remaining == 0 and powModI64(base, order div remaining, modulus) == 1:
      order = order div remaining
  order

proc multiplicative_order*(input: I64Array, length: csize_t): int64
    {.cdecl, exportc: "multiplicative_order".} =
  if input.isNil or length != 2: return -1
  let base = input[0]
  let modulus = input[1]
  if modulus < 2 or modulus > 1000 or base < 0 or base >= modulus: return -1
  if gcdI64(base, modulus) != 1: return 0
  reduceOrder(base, modulus, totientI64(modulus))
