const InvalidResult = -1'i64
const Dimension = 32
const Modulus = 3329'i64
const Samples = 128
const MaxMessageBytes = 4
const MaxParseableLength = 8358
const FnvOffsetBasis = 14695981039346656037'u64
const FnvPrime = 1099511628211'u64
const Low63Mask = 0x7fffffffffffffff'u64

type I64Input = ptr UncheckedArray[int64]

proc hashByte(hashInput: uint64, byte: uint8): uint64 =
  ((hashInput xor uint64(byte)) *% FnvPrime)

proc hashWord(hashInput: uint64, value: int64): uint64 =
  var hash = hashByte(hashInput, uint8(value and 255))
  hash = hashByte(hash, uint8((value shr 8) and 255))
  hash

proc lwe_encryption*(values: I64Input, length: csize_t): int64 {.cdecl, exportc: "lwe_encryption".} =
  if values == nil or length < 1 or length > csize_t(MaxParseableLength): return InvalidResult
  let messageLengthValue = values[0]
  if messageLengthValue < 1 or messageLengthValue > int64(MaxMessageBytes): return InvalidResult
  let messageLength = int(messageLengthValue)
  let messageStart = 1
  let messageEnd = messageStart + messageLength
  let secretStart = messageEnd
  let matrixStart = secretStart + Dimension
  let errorStart = matrixStart + Samples * Dimension
  let subsetStart = errorStart + Samples
  let subsetCount = messageLength * 8 * Samples
  if int(length) != subsetStart + subsetCount: return InvalidResult

  for i in 0 ..< messageLength:
    if values[messageStart + i] < 0 or values[messageStart + i] > 255: return InvalidResult
  for j in 0 ..< Dimension:
    if values[secretStart + j] < 0 or values[secretStart + j] >= Modulus: return InvalidResult
  for i in 0 ..< Samples * Dimension:
    if values[matrixStart + i] < 0 or values[matrixStart + i] >= Modulus: return InvalidResult
  for i in 0 ..< Samples:
    if values[errorStart + i] < 0 or values[errorStart + i] > 6: return InvalidResult
  for i in 0 ..< subsetCount:
    if values[subsetStart + i] != 0 and values[subsetStart + i] != 1: return InvalidResult

  var publicB: array[Samples, int64]
  for row in 0 ..< Samples:
    var sum = 0'i64
    for column in 0 ..< Dimension:
      sum += values[matrixStart + row * Dimension + column] * values[secretStart + column]
    let error = values[errorStart + row] - 3
    var reduced = (sum + error) mod Modulus
    if reduced < 0: reduced += Modulus
    publicB[row] = reduced

  var hash = FnvOffsetBasis
  var decodedMessage: array[MaxMessageBytes, uint8]
  var subsetCursor = 0
  for byteIndex in 0 ..< messageLength:
    let messageByte = uint8(values[messageStart + byteIndex])
    var decodedByte = 0'u8
    for bitIndex in 0 ..< 8:
      let messageBit = (messageByte shr (7 - bitIndex)) and 1'u8
      var uAccumulator: array[Dimension, int64]
      var vAccumulator = int64(messageBit) * (Modulus div 2)
      for row in 0 ..< Samples:
        let selected = values[subsetStart + subsetCursor]
        inc subsetCursor
        if selected != 0:
          for column in 0 ..< Dimension:
            uAccumulator[column] += values[matrixStart + row * Dimension + column]
          vAccumulator += publicB[row]
      var u: array[Dimension, int64]
      for column in 0 ..< Dimension:
        u[column] = uAccumulator[column] mod Modulus
        hash = hashWord(hash, u[column])
      let v = vAccumulator mod Modulus
      hash = hashWord(hash, v)

      var dot = 0'i64
      for column in 0 ..< Dimension:
        dot += u[column] * values[secretStart + column]
      var difference = (v - dot) mod Modulus
      if difference < 0: difference += Modulus
      let decryptedBit = if difference >= 832 and difference < 2496: 1'u8 else: 0'u8
      decodedByte = (decodedByte shl 1) or decryptedBit
    decodedMessage[byteIndex] = decodedByte
  for i in 0 ..< messageLength:
    hash = hashByte(hash, decodedMessage[i])
  int64(hash and Low63Mask)
