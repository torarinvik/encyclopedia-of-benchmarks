const
  MaxInputLength = 64
  MaxParseableInputLength = 65
  InvalidResult = -2_147_483_649'i64
  UInt32Modulus = 4_294_967_296'u64

type I64Input = ptr UncheckedArray[int64]

proc hexa_decimal_to_decimal*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "hexa_decimal_to_decimal".} =
  if length > csize_t(MaxParseableInputLength): return InvalidResult
  if length == 0: return 0
  if length > csize_t(MaxInputLength) or input == nil: return InvalidResult

  var accumulator = 0'u64
  for index in 0 ..< int(length):
    let code = input[index]
    var digit: int64
    if code >= 48 and code <= 57: digit = code - 48
    elif code >= 65 and code <= 70: digit = code - 55
    elif code >= 97 and code <= 102: digit = code - 87
    else: return InvalidResult
    accumulator = (accumulator * 16'u64 + uint64(digit)) mod UInt32Modulus
  if accumulator <= 2_147_483_647'u64: return int64(accumulator)
  int64(accumulator) - 4_294_967_296'i64
