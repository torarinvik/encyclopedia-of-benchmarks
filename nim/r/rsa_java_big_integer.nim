const InvalidResult = -1'i64
const MaxInputLength = 69
const FnvOffsetBasis = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64
const Low63Mask = 0x7fff_ffff_ffff_ffff'u64

type I64Input = ptr UncheckedArray[int64]

proc bigIntegerModPow(base, exponentInput, modulus: int64): int64 =
  var exponent = exponentInput
  var resultValue = 1'i64
  var power = base mod modulus
  while exponent > 0:
    if (exponent and 1) != 0: resultValue = (resultValue * power) mod modulus
    power = (power * power) mod modulus
    exponent = exponent div 2
  resultValue

proc hashU32(hashInput: uint64, value: int64): uint64 =
  var hash = hashInput
  let bits = uint32(value)
  for byteIndex in 0 ..< 4:
    hash = (hash xor uint64((bits shr (byteIndex * 8)) and 255'u32)) *% FnvPrime
  hash

proc rsa_java_big_integer*(packed: I64Input, length: csize_t): int64 {.cdecl, exportc: "rsa_java_big_integer".} =
  if packed == nil or length < 5 or length > csize_t(MaxInputLength): return InvalidResult
  let modulus = packed[0]
  let publicExponent = packed[1]
  let privateExponent = packed[2]
  let messageLength = packed[3]
  if modulus < 128 or modulus > 55295 or publicExponent < 1 or publicExponent > 1_000_000 or
      privateExponent < 1 or privateExponent > 1_000_000 or messageLength < 1 or messageLength > 64 or
      length != csize_t(4 + messageLength): return InvalidResult
  for i in 0 ..< int(messageLength):
    let value = packed[4 + i]
    if value < 0 or value > 127 or value >= modulus: return InvalidResult
  var hash = FnvOffsetBasis
  for i in 0 ..< int(messageLength):
    hash = hashU32(hash, bigIntegerModPow(packed[4 + i], publicExponent, modulus))
  for i in 0 ..< int(messageLength):
    let ciphertext = bigIntegerModPow(packed[4 + i], publicExponent, modulus)
    hash = hashU32(hash, bigIntegerModPow(ciphertext, privateExponent, modulus))
  int64(hash and Low63Mask)
