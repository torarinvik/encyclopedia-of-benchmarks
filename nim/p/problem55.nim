const MaxLimit = 10_000'i64
const MaxDigits = 64

proc reverseAdd(digits: var array[MaxDigits, uint8], length: int): int =
  var reverseLength = length
  while reverseLength > 0 and digits[length - reverseLength] == 0'u8:
    reverseLength -= 1
  let combinedLength = max(length, reverseLength)
  var next: array[MaxDigits, uint8]
  var carry = 0
  for position in 0 ..< combinedLength:
    let left = if position < length: int(digits[position]) else: 0
    let right = if position < reverseLength: int(digits[length - 1 - position]) else: 0
    let sum = left + right + carry
    next[position] = (sum mod 10).uint8
    carry = sum div 10
  var nextLength = combinedLength
  if carry > 0:
    next[nextLength] = carry.uint8
    nextLength += 1
  for index in 0 ..< nextLength:
    digits[index] = next[index]
  nextLength

proc isPalindrome(digits: array[MaxDigits, uint8], length: int): bool =
  for left in 0 ..< length div 2:
    if digits[left] != digits[length - 1 - left]: return false
  true

proc problem55*(limit: int64): int64 {.cdecl, exportc: "problem55".} =
  if limit < 0 or limit > MaxLimit: return -1
  var count = 0'i64
  for start in 1'i64 ..< limit:
    var digits: array[MaxDigits, uint8]
    var length = 0
    var value = start
    while value > 0:
      digits[length] = (value mod 10).uint8
      length += 1
      value = value div 10
    var becamePalindrome = false
    for iteration in 0 ..< 50:
      length = reverseAdd(digits, length)
      if isPalindrome(digits, length):
        becamePalindrome = true
        break
    if not becamePalindrome: count += 1
  count
