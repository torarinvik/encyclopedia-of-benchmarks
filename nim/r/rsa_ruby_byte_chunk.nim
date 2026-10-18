const InvalidResult = -1'i64
const MaxInputLength = 69
const FnvOffsetBasis = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64
const Low63Mask = 0x7fff_ffff_ffff_ffff'u64

type I64Input = ptr UncheckedArray[int64]

proc boundedPower(base, exponent: int64): int64 =
  var resultValue = 1'i64
  for _ in 0 ..< int(exponent): resultValue *= base
  resultValue

proc hashByte(hashInput: uint64, value: uint8): uint64 =
  (hashInput xor uint64(value)) *% FnvPrime

proc rsa_ruby_byte_chunk*(packed: I64Input, length: csize_t): int64 {.cdecl, exportc: "rsa_ruby_byte_chunk".} =
  if packed == nil or length < 5 or length > csize_t(MaxInputLength): return InvalidResult
  let modulus = packed[0]
  let publicExponent = packed[1]
  let privateExponent = packed[2]
  let messageLength = packed[3]
  if modulus != 33 or publicExponent < 1 or publicExponent > 7 or privateExponent < 1 or privateExponent > 7 or
      messageLength < 1 or messageLength > 64 or length != csize_t(4 + messageLength): return InvalidResult
  for i in 0 ..< int(messageLength):
    if packed[4 + i] < 0 or packed[4 + i] >= modulus: return InvalidResult
  var ciphertexts: array[64, int64]
  for i in 0 ..< int(messageLength):
    ciphertexts[i] = boundedPower(packed[4 + i], publicExponent) mod modulus
  var hash = FnvOffsetBasis
  for i in 0 ..< int(messageLength):
    let value = ciphertexts[i]
    hash = hashByte(hash, uint8(48 + value div 10))
    hash = hashByte(hash, uint8(48 + value mod 10))
  for i in 0 ..< int(messageLength):
    let recovered = boundedPower(ciphertexts[i], privateExponent) mod modulus
    hash = hashByte(hash, uint8(recovered))
  int64(hash and Low63Mask)
