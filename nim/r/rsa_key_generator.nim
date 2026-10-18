const InvalidResult = -1'i64
const MinKeySize = 2'i64
const MaxKeySize = 20'i64
const MaxDraws = 1024'i64
const MaxPackedLength = 1027
const FnvOffsetBasis = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64
const Low63Mask = 0x7fffffffffffffff'u64

type
  I64Input = ptr UncheckedArray[int64]
  DrawState = object
    values: I64Input
    length: int
    cursor: int
    keySize: int64
    failed: bool

proc nextDraw(state: var DrawState, low, high: int64, value: var int64): bool =
  if state.cursor >= state.length:
    state.failed = true
    return false
  let drawn = state.values[state.cursor]
  inc state.cursor
  if drawn < low or drawn >= high:
    state.failed = true
    return false
  value = drawn
  true

proc gcdI64(aInput, bInput: int64): int64 =
  var a = aInput
  var b = bInput
  while b != 0:
    let remainder = a mod b
    a = b
    b = remainder
  if a < 0: -a else: a

proc powerModI64(base, exponentInput, modulus: int64): int64 =
  var exponent = exponentInput
  var resultValue = 1'i64
  var power = base mod modulus
  while exponent > 0:
    if (exponent and 1) != 0: resultValue = (resultValue * power) mod modulus
    power = (power * power) mod modulus
    exponent = exponent div 2
  resultValue

proc rabinMiller(num: int64, state: var DrawState): bool =
  var s = num - 1
  var t = 0'i64
  while s mod 2 == 0:
    s = s div 2
    inc t
  for round in 0 ..< 5:
    var base: int64
    if not nextDraw(state, 2, num - 1, base): return false
    var value = powerModI64(base, s, num)
    if value != 1:
      var i = 0'i64
      while value != num - 1:
        if i == t - 1: return false
        inc i
        value = (value * value) mod num
  true

proc isPrimeLowNum(num: int64, state: var DrawState): bool =
  if num < 2: return false
  if num <= 997:
    var divisor = 2'i64
    while divisor * divisor <= num:
      if num mod divisor == 0: return false
      inc divisor
    return true
  for divisor in 2'i64 .. 997'i64:
    if num mod divisor == 0: return false
  rabinMiller(num, state)

proc generateLargePrime(state: var DrawState, prime: var int64): bool =
  let low = 1'i64 shl (state.keySize - 1)
  let high = 1'i64 shl state.keySize
  while not state.failed:
    var candidate: int64
    if not nextDraw(state, low, high, candidate): return false
    if isPrimeLowNum(candidate, state):
      prime = candidate
      return true
  false

proc findModInverse(a, modulus: int64): int64 =
  if gcdI64(a, modulus) != 1: return InvalidResult
  var u1 = 1'i64
  var u2 = 0'i64
  var u3 = a
  var v1 = 0'i64
  var v2 = 1'i64
  var v3 = modulus
  while v3 != 0:
    let quotient = u3 div v3
    let nextV1 = u1 - quotient * v1
    let nextV2 = u2 - quotient * v2
    let nextV3 = u3 - quotient * v3
    u1 = v1; u2 = v2; u3 = v3
    v1 = nextV1; v2 = nextV2; v3 = nextV3
  u1 mod modulus

proc hashI64(hashInput: uint64, value: int64): uint64 =
  var hash = hashInput
  let bits = cast[uint64](value)
  for byteIndex in 0 ..< 8:
    hash = (hash xor ((bits shr (byteIndex * 8)) and 255'u64)) *% FnvPrime
  hash

proc rsa_key_generator*(packed: I64Input, length: csize_t): int64 {.cdecl, exportc: "rsa_key_generator".} =
  if packed == nil or length < 2 or length > csize_t(MaxPackedLength): return InvalidResult
  let keySize = packed[0]
  let drawCount = packed[1]
  if keySize < MinKeySize or keySize > MaxKeySize or drawCount < 0 or drawCount > MaxDraws or
      length != csize_t(2 + drawCount): return InvalidResult
  let drawLimit = 1'i64 shl keySize
  for i in 0 ..< int(drawCount):
    if packed[2 + i] < 2 or packed[2 + i] >= drawLimit: return InvalidResult

  var state = DrawState(values: packed, length: int(length), cursor: 2, keySize: keySize, failed: false)
  var p, q: int64
  if not generateLargePrime(state, p) or not generateLargePrime(state, q): return InvalidResult
  let n = p * q
  let phi = (p - 1) * (q - 1)
  let low = 1'i64 shl (keySize - 1)
  let high = 1'i64 shl keySize
  var e: int64
  while true:
    if not nextDraw(state, low, high, e): return InvalidResult
    if gcdI64(e, phi) == 1: break
  let d = findModInverse(e, phi)
  var hash = FnvOffsetBasis
  hash = hashI64(hash, n)
  hash = hashI64(hash, e)
  hash = hashI64(hash, n)
  hash = hashI64(hash, d)
  int64(hash and Low63Mask)
