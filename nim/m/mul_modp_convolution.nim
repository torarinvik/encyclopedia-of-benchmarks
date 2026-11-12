const MaxP = 97
const MaxInput = 196
const MaxOutput = 776
const Mod = 998_244_353'i64

proc powMod(baseInput: int64, exponentInput: int, modulus: int): int =
  var base = baseInput mod int64(modulus)
  var exponent = exponentInput
  var result = 1'i64
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod int64(modulus)
    base = base * base mod int64(modulus)
    exponent = exponent shr 1
  int(result)

proc isPrime(p: int): bool =
  if p < 2: return false
  var d = 2
  while d * d <= p:
    if p mod d == 0: return false
    inc d
  true

proc primitiveRoot(p: int): int =
  let order = p - 1
  for candidate in 1 ..< p:
    var good = true
    for factor in 2 .. order:
      if order mod factor == 0 and isPrime(factor) and powMod(candidate, order div factor, p) == 1:
        good = false
        break
    if good: return candidate
  1

proc storeLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc mul_modp_convolution*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "mul_modp_convolution".} =
  if input == nil or length < 5 or length > csize_t(MaxInput): return -1
  let p0 = input[0]
  if p0 < 2 or p0 > MaxP or not isPrime(int(p0)): return -1
  let p = int(p0)
  if int(length) != 1 + 2 * p: return -1
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] >= Mod: return -1
  let bytes = 8 * p
  if bytes > MaxOutput: return -1
  if output == nil or int(capacity) < bytes: return -2
  var a, b, left, right, cyclic, result: array[MaxP, int64]
  var byExp: array[MaxP, int]
  for i in 0 ..< p: a[i] = input[1 + i]; b[i] = input[1 + p + i]
  let q = p - 1
  let root = primitiveRoot(p)
  var residue = 1
  for e in 0 ..< q: byExp[e] = residue; residue = residue * root mod p
  for e in 0 ..< q: left[e] = a[byExp[e]]; right[e] = b[byExp[e]]
  for i in 0 ..< q:
    for j in 0 ..< q:
      let slot = (i + j) mod q
      cyclic[slot] = (cyclic[slot] + left[i] * right[j] mod Mod) mod Mod
  var sumA, sumB = 0'i64
  for i in 0 ..< p: sumA = (sumA + a[i]) mod Mod
  for i in 1 ..< p: sumB = (sumB + b[i]) mod Mod
  result[0] = (sumA * b[0] mod Mod + a[0] * sumB mod Mod) mod Mod
  for e in 0 ..< q: result[byExp[e]] = cyclic[e]
  for i in 0 ..< p: storeLe(output, 8 * i, result[i])
  int64(bytes)
