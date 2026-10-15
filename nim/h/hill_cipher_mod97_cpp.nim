type I64Input = ptr UncheckedArray[int64]
type U8Output = ptr UncheckedArray[uint8]
const Alphabet: array[97, int64] = [65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32]
const EncryptKey: array[4, int64] = [2, 5, 1, 6]
const DecryptKey: array[4, int64] = [84, 27, 83, 28]

proc alphabetIndex(value: int64): int =
  for index in 0 ..< 97:
    if Alphabet[index] == value: return index
  -1

proc hill_cipher_mod97_cpp*(values: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "hill_cipher_mod97_cpp".} =
  if values == nil or length < 3 or length > 258: return -1
  let operation = values[0]
  let rawLength = values[1]
  if (operation != 0 and operation != 1) or rawLength < 1 or rawLength > 256 or length != csize_t(rawLength + 2): return -1
  let textLength = int(rawLength)
  var indices: array[256, uint8]
  for index in 0 ..< textLength:
    let mapped = alphabetIndex(values[index + 2])
    if mapped < 0: return -1
    indices[index] = uint8(mapped)
  let outputLength = textLength + textLength mod 2
  if output == nil or outputCapacity < csize_t(outputLength): return -2
  let key = if operation == 0: EncryptKey else: DecryptKey
  for offset in countup(0, outputLength - 1, 2):
    let first = int64(indices[offset])
    let second = if offset + 1 < textLength: int64(indices[offset + 1]) else: 0'i64
    let row0 = int((key[0] * first + key[1] * second) mod 97)
    let row1 = int((key[2] * first + key[3] * second) mod 97)
    output[offset] = uint8(Alphabet[row0])
    output[offset + 1] = uint8(Alphabet[row1])
  int64(outputLength)
