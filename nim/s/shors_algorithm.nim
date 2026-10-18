const MinModulus = 2'i64
const MaxModulus = 255'i64
const MinAttempts = 1'i64
const MaxAttempts = 16'i64
const InvalidResult = -1'i64

type I64Input = ptr UncheckedArray[int64]

proc gcdI64(aInput, bInput: int64): int64 =
  var a = aInput
  var b = bInput
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  a

proc shors_algorithm*(packed: I64Input, length: csize_t): int64 {.cdecl, exportc: "shors_algorithm".} =
  if packed == nil or length < 3 or length > 19: return InvalidResult
  let modulus = packed[0]
  let attempts = packed[1]
  if modulus < MinModulus or modulus > MaxModulus or attempts < MinAttempts or attempts > MaxAttempts or length != csize_t(2 + attempts): return InvalidResult
  for index in 0 ..< int(attempts):
    let base = packed[2 + index]
    if base < 2 or base > modulus: return InvalidResult

  for index in 0 ..< int(attempts):
    let base = packed[2 + index]
    let common = gcdI64(base, modulus)
    if common != 1: return common
    var order = 1'i64
    var power = base mod modulus
    while power != 1 and order < modulus - 1:
      power = (power * base) mod modulus
      inc order
    if power != 1: return InvalidResult
    if order mod 2 == 1: continue

    var halfPower = 1'i64
    for _ in 0 ..< int(order div 2):
      halfPower = (halfPower * base) mod modulus
    let upper = halfPower + 1
    let lower = halfPower - 1
    if upper mod modulus == 0 or lower mod modulus == 0: continue
    let upperGcd = gcdI64(upper, modulus)
    if upperGcd != 1: return upperGcd
    return gcdI64(lower, modulus)
  InvalidResult
