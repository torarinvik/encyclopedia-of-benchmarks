const InvalidResult = low(int64)
const UInt32Modulus = 4_294_967_296'i64

proc parse_integer*(bytes: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "parse_integer".} =
  if bytes == nil or length == 0 or length > 64: return InvalidResult
  for index in 0 ..< int(length):
    if bytes[index] < 0 or bytes[index] > 127: return InvalidResult
  let negative = bytes[0] == 45
  var index = if bytes[0] == 45 or bytes[0] == 43: 1 else: 0
  var number = 0'i64
  while index < int(length):
    let byte = bytes[index]
    if byte < 48 or byte > 57: return InvalidResult
    number = (number * 10 + byte - 48) mod UInt32Modulus
    index += 1
  if negative and number != 0: number = UInt32Modulus - number
  if number >= 2_147_483_648'i64: return number - UInt32Modulus
  number
