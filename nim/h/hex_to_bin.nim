## Return the decimal integer formed by the binary digits of a bounded hex value.
const InvalidResult = low(int64)

proc hexDigit(byte: int64): int64 =
  if byte >= 48 and byte <= 57: return byte - 48
  if byte >= 65 and byte <= 70: return byte - 65 + 10
  if byte >= 97 and byte <= 102: return byte - 97 + 10
  -1

proc hex_to_bin*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hex_to_bin".} =
  if input.isNil or length < 1 or length > 5: return InvalidResult
  var start = 0
  var sign: int64 = 1
  if input[0] == 45:
    sign = -1
    start = 1
  if int(length) - start < 1 or int(length) - start > 4: return InvalidResult

  var value: int64 = 0
  for index in start ..< int(length):
    let digit = hexDigit(input[index])
    if digit < 0: return InvalidResult
    value = value * 16 + digit
  if value == 0: return InvalidResult

  var decimalBinaryDigits: int64 = 0
  var place: int64 = 1
  while value > 0:
    decimalBinaryDigits += (value mod 2) * place
    value = value div 2
    if value > 0: place *= 10
  sign * decimalBinaryDigits
