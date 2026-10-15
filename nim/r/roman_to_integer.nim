## Decode canonical uppercase Roman numerals in the range 1 through 3,999.
proc decodeRomanDigit(symbols: ptr UncheckedArray[int64], length, position: csize_t,
    one, five, ten: int64): int64 =
  if position >= length: return 0
  if symbols[position] == one:
    if position + 1 < length and symbols[position + 1] == ten: return 146
    if position + 1 < length and symbols[position + 1] == five: return 66
    var count = csize_t(0)
    while position + count < length and symbols[position + count] == one and count < 3:
      inc count
    if position + count < length and symbols[position + count] == one: return -1
    return int64(count * 16 + count)
  if symbols[position] == five:
    var count = csize_t(0)
    while position + 1 + count < length and symbols[position + 1 + count] == one and count < 3:
      inc count
    if position + 1 + count < length and symbols[position + 1 + count] == one: return -1
    return int64((5 + count) * 16 + 1 + count)
  0

proc roman_to_integer*(symbols: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "roman_to_integer".} =
  if length == 0 or length > 15: return -1
  for index in 0 ..< length:
    let symbol = symbols[index]
    if symbol notin [73'i64, 86'i64, 88'i64, 76'i64, 67'i64, 68'i64, 77'i64]: return -1
  var position = csize_t(0)
  var thousands = csize_t(0)
  while position < length and symbols[position] == 77 and thousands < 3:
    inc position
    inc thousands
  if position < length and symbols[position] == 77: return -1
  let hundreds = decodeRomanDigit(symbols, length, position, 67, 68, 77)
  if hundreds < 0: return -1
  position += csize_t(hundreds and 15)
  let tens = decodeRomanDigit(symbols, length, position, 88, 76, 67)
  if tens < 0: return -1
  position += csize_t(tens and 15)
  let ones = decodeRomanDigit(symbols, length, position, 73, 86, 88)
  if ones < 0: return -1
  position += csize_t(ones and 15)
  if position != length: return -1
  let value = int64(thousands) * 1000 + (hundreds shr 4) * 100 + (tens shr 4) * 10 + (ones shr 4)
  if value < 1 or value > 3999: return -1
  value
