proc countReversible(remaining, carryIn: int64, digits: var array[9, int64], length: int64): int64 =
  if remaining == 0:
    if digits[0] == 0 or digits[int(length - 1)] == 0: return 0
    var carry = carryIn
    var i = length div 2 - 1
    while i >= 0:
      carry += digits[int(i)] + digits[int(length - i - 1)]
      if carry mod 2 == 0: return 0
      carry = carry div 10
      dec i
    return 1
  if remaining == 1:
    if carryIn mod 2 == 0: return 0
    var result = 0'i64
    for digit in 0'i64..9'i64:
      digits[int(length div 2)] = digit
      result += countReversible(0, (carryIn + 2 * digit) div 10, digits, length)
    return result
  var result = 0'i64
  let rightIndex = int((length + remaining) div 2 - 1)
  let leftIndex = int((length - remaining) div 2)
  for digit1 in 0'i64..9'i64:
    digits[rightIndex] = digit1
    let parity = if (carryIn + digit1) mod 2 == 0: 1'i64 else: 0'i64
    var digit2 = parity
    while digit2 < 10:
      digits[leftIndex] = digit2
      result += countReversible(remaining - 2, (carryIn + digit1 + digit2) div 10, digits, length)
      digit2 += 2
  result

proc problem145*(maxPower: int64): int64 {.cdecl, exportc: "problem145".} =
  if maxPower > 9: return -1
  if maxPower <= 0: return 0
  var digits: array[9, int64]
  var total = 0'i64
  for length in 1..int(maxPower):
    if (length - 1) mod 4 != 0:
      total += countReversible(int64(length), 0, digits, int64(length))
  total
