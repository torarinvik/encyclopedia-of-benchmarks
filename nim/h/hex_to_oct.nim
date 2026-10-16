const InvalidResult: int64 = -2_147_483_649
const I32Modulus = 4_294_967_296'u64

proc hexDigit(code: int64): int =
  if code >= 48 and code <= 57: return int(code - 48)
  if code >= 65 and code <= 70: return int(code - 55)
  if code >= 97 and code <= 102: return int(code - 87)
  -1

proc signedI32(bits: uint64): int64 =
  if bits <= 2_147_483_647'u64: return int64(bits)
  int64(bits) - int64(I32Modulus)

proc hex_to_oct*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hex_to_oct".} =
  if length > 8 or (length != 0 and input.isNil): return InvalidResult
  var decimalBits: uint64 = 0
  for index in 0 ..< int(length):
    let digit = hexDigit(input[index])
    if digit < 0: return InvalidResult
    decimalBits = (decimalBits * 16 + uint64(digit)) mod I32Modulus
  var decimal = signedI32(decimalBits)
  if decimal <= 0: return 0

  var octalBits: uint64 = 0
  var placeValue: uint64 = 1
  while decimal > 0:
    octalBits = (octalBits + uint64(decimal mod 8) * placeValue) mod I32Modulus
    decimal = decimal div 8
    placeValue = (placeValue * 10) mod I32Modulus
  signedI32(octalBits)
